import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const source = readFileSync(new URL('../../public/game_audio.js', import.meta.url), 'utf8')
  .replace('export function createGameAudio', 'function createGameAudio');

class Surface {
  listeners = new Map();
  addEventListener(name, callback) {
    if (!this.listeners.has(name)) this.listeners.set(name, new Set());
    this.listeners.get(name).add(callback);
  }
  removeEventListener(name, callback) { this.listeners.get(name)?.delete(callback); }
  emit(name, event = {}) { for (const callback of this.listeners.get(name) || []) callback({ type: name, ...event }); }
  get listenerCount() { return [...this.listeners.values()].reduce((sum, group) => sum + group.size, 0); }
}

function fixture({ mode = 'drive', muted = false, supported = true, initialState = 'running', rejectResume = false, blockResume = false, storedOnly = false } = {}) {
  const document = new Surface(), window = new Surface(), contexts = [], timers = new Map();
  const toggle = { pressed: String(muted), getAttribute() { return this.pressed; } };
  document.hidden = false;
  document.querySelector = () => storedOnly ? null : toggle;
  window.localStorage = { getItem: () => String(muted) };
  let timerId = 0, resumeAllowed = !blockResume;
  const param = () => ({ value: 0, events: [],
    setValueAtTime(value, time) { this.events.push(['set', value, time]); },
    linearRampToValueAtTime(value, time) { this.events.push(['linear', value, time]); },
    exponentialRampToValueAtTime(value, time) { this.events.push(['exponential', value, time]); }
  });
  class AudioContext {
    constructor() {
      contexts.push(this);
      this.state = initialState; this.currentTime = 0; this.sampleRate = 8000;
      this.sources = []; this.gains = []; this.buffers = []; this.resumeCalls = 0; this.closeCalls = 0;
      this.pendingResumes = [];
    }
    createGain() {
      const gain = { gain: param(), connected: false, connect(to) { this.connected = true; this.to = to; }, disconnect() { this.connected = false; } };
      this.gains.push(gain); return gain;
    }
    makeSource(kind) {
      const node = { kind, frequency: param(), connected: false, stops: [],
        connect(to) { this.connected = true; this.to = to; },
        disconnect() { this.connected = false; }, start(at) { this.startAt = at; },
        stop(at) { this.stops.push(at); if (at === undefined) this.stopped = true; },
        end() { this.stopped = true; this.onended?.(); }
      };
      this.sources.push(node); return node;
    }
    createOscillator() { return this.makeSource('oscillator'); }
    createBufferSource() { return this.makeSource('buffer'); }
    createBuffer(channels, length, rate) {
      const data = Array.from({ length: channels }, () => new Float32Array(length));
      const buffer = { numberOfChannels: channels, length, sampleRate: rate, getChannelData: index => data[index] };
      this.buffers.push(buffer); return buffer;
    }
    resume() {
      this.resumeCalls++;
      if (rejectResume) return Promise.reject(new Error('Audio gesture denied'));
      if (!resumeAllowed) return new Promise(resolve => this.pendingResumes.push(resolve));
      return Promise.resolve().then(() => {
        this.state = 'running'; this.onstatechange?.();
        this.pendingResumes.splice(0).forEach(resolve => resolve());
      });
    }
    suspend() { this.state = 'suspended'; this.onstatechange?.(); return Promise.resolve(); }
    close() { this.closeCalls++; this.state = 'closed'; return Promise.resolve(); }
    advance(seconds) {
      this.currentTime += seconds;
      for (const node of this.sources) if (node.connected && node.stops.some(at => at <= this.currentTime)) node.end();
    }
  }
  if (supported) window.AudioContext = AudioContext;
  let randomSeed = 74293;
  const math = Object.create(Math);
  math.random = () => { randomSeed = (1664525 * randomSeed + 1013904223) >>> 0; return randomSeed / 4294967296; };
  const sandbox = { document, window, queueMicrotask, Promise, Float32Array, Math: math,
    setInterval(callback, milliseconds) { const id = ++timerId; timers.set(id, { callback, milliseconds }); return id; },
    clearInterval(id) { timers.delete(id); }
  };
  runInNewContext(`${source}\nglobalThis.game = createGameAudio(${JSON.stringify(mode)});`, sandbox);
  return {
    game: sandbox.game, document, window, toggle, contexts, timers,
    get context() { return contexts[0]; },
    gesture(event = {}, type = 'pointerdown') { document.emit(type, { isTrusted: true, pointerType: 'mouse', ...event }); },
    allowResume() { resumeAllowed = true; },
    tick(seconds = .08) { contexts[0]?.advance(seconds); for (const timer of [...timers.values()]) timer.callback(); },
    async mute(value) {
      // The document click occurs after application.js changes the button.
      toggle.pressed = String(value);
      document.emit('click', { isTrusted: true, target: { closest: () => toggle } });
      await Promise.resolve();
    }
  };
}

const flush = async () => { await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); };
const live = f => f.context.sources.filter(node => node.connected);

test('music and effects stay silent until a real user gesture', () => {
  const f = fixture();
  f.game.setPlaying(true); f.game.play('win');
  assert.equal(f.contexts.length, 0);
  f.gesture({ isTrusted: false });
  assert.equal(f.contexts.length, 0);
  f.gesture();
  assert.equal(f.contexts.length, 1);
  assert.equal(f.timers.size, 1);
  assert.ok(live(f).length > 0);
  f.game.dispose();
});

test('touch and pen release unlock music and effects without a premature pointerdown resume', async () => {
  for (const pointerType of ['touch', 'pen']) {
    const f = fixture({ initialState: 'suspended' });
    f.game.setPlaying(true);
    f.gesture({ pointerType });
    assert.equal(f.contexts.length, 0, `${pointerType} pointerdown is not an audio activation`);
    f.gesture({ pointerType, isTrusted: false }, 'pointerup');
    assert.equal(f.contexts.length, 0);
    f.gesture({ pointerType }, 'pointerup'); await flush();
    assert.equal(f.context.resumeCalls, 1);
    assert.equal(f.timers.size, 1);
    const musicCount = live(f).length;
    f.game.play('hit');
    assert.ok(live(f).length > musicCount, 'effects work after the same touch release');
    f.game.dispose();
  }
});

test('trusted touchend, click, and ordinary keyboard gestures provide audio fallbacks', async () => {
  for (const type of ['touchend', 'click', 'keydown']) {
    const f = fixture({ initialState: 'suspended' }); f.game.setPlaying(true);
    f.gesture({ isTrusted: false, key: 'ArrowLeft' }, type);
    assert.equal(f.contexts.length, 0);
    f.gesture({ key: 'ArrowLeft' }, type); await flush();
    assert.equal(f.timers.size, 1, type);
    f.game.dispose();
  }
  const f = fixture(); f.game.setPlaying(true);
  for (const event of [{ key: 'Escape' }, { key: 'Shift' }, { key: 'r', ctrlKey: true }, { key: 'ArrowLeft', repeat: true }]) {
    f.gesture(event, 'keydown');
  }
  assert.equal(f.contexts.length, 0, 'shortcuts, modifier keys, and repeat do not unexpectedly start music');
  f.game.dispose();
});

test('fresh touch release retries a blocked pending resume while ordinary calls remain deduplicated', async () => {
  const f = fixture({ initialState: 'suspended', blockResume: true });
  f.game.setPlaying(true); f.gesture();
  await flush();
  assert.equal(f.context.state, 'suspended');
  assert.equal(f.context.pendingResumes.length, 1, 'blocked browser resume stays pending instead of rejecting');
  for (let attempt = 0; attempt < 5; attempt++) { f.game.setPlaying(true); f.game.play('hit'); }
  assert.equal(f.context.resumeCalls, 1);
  f.allowResume();
  f.gesture({ pointerType: 'touch' });
  assert.equal(f.context.resumeCalls, 1, 'touchdown must not retry before activation');
  f.gesture({ pointerType: 'touch' }, 'pointerup'); await flush();
  assert.equal(f.context.resumeCalls, 2);
  assert.equal(f.context.state, 'running'); assert.equal(f.timers.size, 1);
  const musicCount = live(f).length; f.game.play('crash');
  assert.ok(live(f).length > musicCount);
  await f.mute(true); assert.equal(live(f).length, 0);
  await f.mute(false); assert.equal(f.timers.size, 1);
  f.game.dispose();
});

test('a trusted unmute alone unlocks muted loading and retries a previously blocked resume', async () => {
  for (const previouslyBlocked of [false, true]) {
    const f = fixture({ initialState: 'suspended', muted: !previouslyBlocked, blockResume: previouslyBlocked });
    f.game.setPlaying(true);
    f.gesture();
    if (previouslyBlocked) {
      assert.equal(f.context.pendingResumes.length, 1);
      await f.mute(true); f.allowResume();
    } else assert.equal(f.contexts.length, 0);
    await f.mute(false); await flush();
    assert.equal(f.context.state, 'running'); assert.equal(f.timers.size, 1);
    f.game.dispose();
  }
});

test('drive and arena play distinct quiet melodies without multiplying loops', () => {
  const melodies = [];
  for (const mode of ['drive', 'arena']) {
    const f = fixture({ mode }); f.gesture();
    for (let attempt = 0; attempt < 20; attempt++) f.game.setPlaying(true);
    assert.equal(f.timers.size, 1);
    assert.ok(f.context.gains[0].gain.value <= .35);
    assert.ok(f.context.gains[1].gain.value < f.context.gains[2].gain.value);
    melodies.push(f.context.sources[0].frequency.events[0][1]);
    for (let tick = 0; tick < 800; tick++) {
      f.tick();
      assert.ok(live(f).length <= 28);
      assert.equal(f.timers.size, 1);
    }
    const before = f.context.sources.length;
    f.tick(300); // background/throttled callbacks must not replay 300s of notes
    assert.ok(f.context.sources.length - before <= 5);
    assert.ok(f.context.sources.slice(before).every(node => node.startAt >= f.context.currentTime));
    f.game.dispose();
  }
  assert.notEqual(...melodies);
});

test('every requested effect has a different sound, and winning includes stereo handclaps', () => {
  const signatures = [];
  for (const cue of ['turn', 'crash', 'hit', 'miss', 'block', 'tie', 'power', 'win', 'lose']) {
    const f = fixture(); f.gesture(); f.game.play(cue);
    assert.ok(f.context.sources.length > 0, cue);
    const notes = f.context.sources.filter(node => node.kind === 'oscillator').map(node => node.frequency.events[0][1]);
    signatures.push(JSON.stringify([notes, f.context.buffers.map(buffer => buffer.numberOfChannels)]));
    if (cue === 'win') {
      const clap = f.context.sources.find(node => node.buffer?.numberOfChannels === 2);
      assert.ok(clap);
      assert.ok(clap.buffer.length / clap.buffer.sampleRate >= 1.8);
      assert.ok(clap.buffer.getChannelData(0).some(value => value !== 0));
      assert.ok(clap.buffer.getChannelData(0).slice(8000).some(value => value !== 0));
      assert.notDeepEqual(clap.buffer.getChannelData(0), clap.buffer.getChannelData(1));
      assert.ok(clap.to.gain.events.some(([kind, , at]) => kind === 'set' && at > 1));
      assert.ok(notes.every((note, index) => index === 0 || note > notes[index - 1]));
    }
    if (cue === 'lose') assert.ok(notes.every((note, index) => index === 0 || note < notes[index - 1]));
    f.game.dispose();
  }
  assert.equal(new Set(signatures).size, signatures.length);
});

test('stopping music leaves the ending cue alive, while muting cuts off all scheduled sound', async () => {
  const f = fixture(); f.gesture(); f.game.setPlaying(true);
  const music = [...live(f)];
  f.game.setPlaying(false); f.game.play('win');
  assert.equal(f.timers.size, 0);
  assert.ok(music.every(node => !node.connected && node.stopped));
  assert.ok(live(f).length > 0);
  await f.mute(true);
  assert.equal(live(f).length, 0);
  assert.ok(f.context.sources.every(node => node.stopped));
  const count = f.context.sources.length;
  f.game.play('crash'); await f.mute(false);
  assert.equal(f.context.sources.length, count, 'unmute must not replay applause or resume a finished game');
  f.game.dispose();
});

test('mute toggle and cross-tab storage stop immediately and resume only wanted music', async () => {
  const f = fixture(); f.gesture(); f.game.setPlaying(true);
  await f.mute(true);
  assert.equal(f.timers.size, 0); assert.equal(live(f).length, 0);
  await f.mute(false);
  assert.equal(f.timers.size, 1);
  f.window.emit('storage', { key: 'cirilo-muted', newValue: 'true' });
  assert.equal(f.timers.size, 0); assert.equal(live(f).length, 0);
  const count = f.context.sources.length;
  f.game.play('hit'); f.game.setPlaying(true);
  assert.equal(f.context.sources.length, count, 'stale unmuted DOM cannot override another tab');
  f.window.emit('storage', { key: 'something-else', newValue: 'false' });
  assert.equal(f.timers.size, 0);
  f.window.emit('storage', { key: 'cirilo-muted', newValue: 'false' });
  assert.equal(f.timers.size, 1);
  f.game.dispose();
});

test('muted loading and unavailable audio never interrupt either game', async () => {
  for (const options of [{ muted: true }, { muted: true, storedOnly: true }, { supported: false }]) {
    const f = fixture(options);
    f.game.setPlaying(true); f.gesture(); f.game.play('win'); await flush();
    assert.equal(f.contexts.length, 0); assert.equal(f.timers.size, 0);
    f.game.dispose(); f.game.dispose();
  }
});

test('tab hiding stops sound and resumes music without replaying effects', async () => {
  const f = fixture(); f.gesture(); f.game.setPlaying(true); f.game.play('hit');
  f.document.hidden = true; f.document.emit('visibilitychange');
  assert.equal(f.context.state, 'suspended'); assert.equal(live(f).length, 0); assert.equal(f.timers.size, 0);
  f.game.play('win');
  f.document.hidden = false; f.document.emit('visibilitychange'); await flush();
  assert.equal(f.timers.size, 1);
  assert.ok(live(f).every(node => node.kind === 'oscillator'));
  f.game.dispose();
});

test('ordinary async resume calls are deduplicated, rejected resumes are harmless, and late completion respects mute', async () => {
  for (const rejectResume of [false, true]) {
    const f = fixture({ initialState: 'suspended', rejectResume });
    f.game.setPlaying(true); f.gesture(); f.game.setPlaying(true); f.game.play('hit');
    assert.equal(f.context.resumeCalls, 1);
    await flush();
    assert.equal(f.timers.size, rejectResume ? 0 : 1);
    f.game.dispose();
  }
  const f = fixture({ initialState: 'suspended' });
  f.game.setPlaying(true); f.gesture();
  f.window.emit('storage', { key: 'cirilo-muted', newValue: 'true' });
  await flush();
  assert.equal(live(f).length, 0); assert.equal(f.timers.size, 0);
  f.game.dispose();
});

test('repeated effects cannot accumulate voices and ended nodes disconnect', () => {
  const f = fixture(); f.gesture();
  for (let tap = 0; tap < 100; tap++) {
    f.context.currentTime += .08;
    f.game.play(tap % 2 ? 'win' : 'crash');
    assert.ok(live(f).length <= 28);
  }
  for (const node of [...live(f)]) node.end();
  assert.equal(live(f).length, 0);
  assert.ok(f.context.gains.slice(3).every(gain => !gain.connected));
  f.game.dispose();
});

test('pagehide closes audio, releases listeners, and late calls cannot restart it', async () => {
  const f = fixture({ initialState: 'suspended' });
  f.game.setPlaying(true); f.gesture(); f.window.emit('pagehide'); await flush();
  assert.equal(f.context.closeCalls, 1);
  assert.equal(f.document.listenerCount, 0); assert.equal(f.window.listenerCount, 0);
  assert.equal(f.timers.size, 0); assert.equal(live(f).length, 0);
  f.game.setPlaying(true); f.game.play('win'); f.game.dispose();
  assert.equal(f.contexts.length, 1); assert.equal(f.context.closeCalls, 1);
});

test('Browser Back restores cached arena audio but does not resume a paused driving game', async () => {
  for (const driving of [false, true]) {
    const f = fixture({ mode: driving ? 'drive' : 'arena' });
    f.game.setPlaying(true); f.gesture(); f.game.play('hit');
    f.window.emit('pagehide', { persisted: true });
    if (driving) f.game.setPlaying(false); // driving controller shows its Resume overlay
    assert.equal(f.context.closeCalls, 0);
    assert.equal(f.timers.size, 0); assert.equal(live(f).length, 0);
    f.gesture(); f.game.play('win');
    assert.equal(live(f).length, 0, 'a cached page is silent even before document.hidden changes');
    f.window.emit('pageshow', { persisted: true }); await flush();
    assert.equal(f.timers.size, driving ? 0 : 1);
    if (driving) { f.gesture(); f.game.setPlaying(true); }
    assert.equal(f.timers.size, 1);
    assert.equal(f.contexts.length, 1);
    assert.ok(live(f).every(node => node.kind === 'oscillator'), 'old applause/hit effects are not replayed');
    f.game.dispose();
  }
});

test('cached pages re-read mute when restored, including a changed setting on another page', async () => {
  const f = fixture(); f.gesture(); f.game.setPlaying(true);
  f.window.emit('pagehide', { persisted: true });
  f.window.localStorage.getItem = () => 'true';
  f.window.emit('pageshow', { persisted: true }); await flush();
  assert.equal(f.timers.size, 0); assert.equal(live(f).length, 0);
  f.gesture(); f.game.play('hit');
  assert.equal(live(f).length, 0);
  await f.mute(false);
  await flush();
  assert.equal(f.timers.size, 1);
  f.game.dispose();
});

test('applause has short changing transients with headroom, rather than a clipped steady noise', () => {
  const f = fixture(); f.gesture(); f.game.play('win');
  const clap = f.context.sources.find(node => node.buffer?.numberOfChannels === 2);
  const samples = clap.buffer.getChannelData(0);
  let peak = 0, squareSum = 0;
  for (const sample of samples) { peak = Math.max(peak, Math.abs(sample)); squareSum += sample * sample; }
  const rms = Math.sqrt(squareSum / samples.length);
  const busGain = f.context.gains[0].gain.value * f.context.gains[2].gain.value * .75;
  assert.ok(peak * busGain <= .12, 'clap peaks retain substantial headroom');
  assert.ok(rms > .01 && rms < .2);
  assert.ok(peak / rms > 3, 'transient peaks are stronger than the background');
  const windows = [];
  for (let offset = 0; offset < 12800; offset += 80) {
    const segment = samples.slice(offset, offset + 80);
    windows.push(Math.sqrt(segment.reduce((sum, value) => sum + value * value, 0) / segment.length));
  }
  assert.ok(Math.max(...windows) > 3 * windows.reduce((sum, value) => sum + value, 0) / windows.length);
  f.game.dispose();
});
