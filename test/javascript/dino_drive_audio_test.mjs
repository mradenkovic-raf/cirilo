import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { appendDriveMove, driveFrameDelta, evaluateDrive } from '../../public/dino_drive_engine.js';

// Run the shipped controller with the real driving rules, simulated taps and
// animation time. The audio engine itself has separate sound/mute tests.
const controller = readFileSync(new URL('../../public/dino_drive.js', import.meta.url), 'utf8')
  .replace(/^import .*;$/gm, '');

class Element {
  constructor() {
    this.dataset = {}; this.attributes = {}; this.listeners = {}; this.children = [];
    this.hidden = false; this.disabled = false; this.textContent = '';
    this.style = { setProperty(name, value) { this[name] = value; } };
    const classes = new Set();
    this.classList = {
      contains: name => classes.has(name),
      add: (...names) => names.forEach(name => classes.add(name)),
      remove: (...names) => names.forEach(name => classes.delete(name)),
      toggle(name, enabled = !classes.has(name)) { enabled ? classes.add(name) : classes.delete(name); }
    };
  }
  setAttribute(name, value) { this.attributes[name] = String(value); }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  async dispatch(name, event = {}) { await Promise.all((this.listeners[name] || []).map(callback => callback(event))); }
  async click() { if (!this.disabled) await this.dispatch('click'); }
  replaceChildren(...children) { this.children = children; }
  append(child) { this.children.push(child); }
  focus() { this.focused = true; }
}

function fixture({ initial = { status: 'ready' }, obstacles = [], finishFailures = 0 } = {}) {
  const nodes = new Map(), music = [], cues = [], bursts = [], requests = [], frames = new Map(), saved = new Map();
  const node = selector => {
    if (!nodes.has(selector)) nodes.set(selector, new Element());
    return nodes.get(selector);
  };
  const root = node('[data-dino-drive]');
  root.dataset = { startUrl: '/drive/start', finishUrl: '/drive/finish', nextUrl: '/mission' };
  root.querySelector = node;
  const course = { status: 'active', token: 'course-token', duration_ms: 24000, max_hits: 3, starting_lane: 1, obstacles };
  node('[data-drive-state]').textContent = JSON.stringify(initial.status === 'ready' ? initial : { ...course, ...initial });
  node('[data-drive-hearts]').children = Array.from({ length: 3 }, () => new Element());
  const document = new Element();
  document.hidden = false;
  document.querySelector = node;
  document.createElement = () => new Element();
  const window = new Element();
  let now = 0, nextFrame = 0;
  runInNewContext(controller, {
    document, window, AbortController, appendDriveMove, driveFrameDelta, evaluateDrive,
    setTimeout: () => 1, clearTimeout() {},
    requestAnimationFrame(callback) { frames.set(++nextFrame, callback); return nextFrame; },
    cancelAnimationFrame(id) { frames.delete(id); },
    sessionStorage: {
      getItem: key => saved.get(key) ?? null,
      setItem: (key, value) => saved.set(key, value),
      removeItem: key => saved.delete(key)
    },
    burst: options => bursts.push(options),
    createGameAudio(mode) {
      assert.equal(mode, 'drive');
      return {
        setPlaying(value) { music.push(value); },
        play(cue) { cues.push(cue); },
        dispose() { music.push(false); }
      };
    },
    async fetch(url, options) {
      const body = JSON.parse(options.body);
      requests.push({ url, body });
      if (url === '/drive/start') return { ok: true, json: async () => ({ success: true, state: structuredClone(course) }) };
      assert.equal(url, '/drive/finish');
      if (finishFailures-- > 0) throw new Error('offline');
      const result = evaluateDrive(course, body.moves, body.elapsed_ms);
      return { ok: true, json: async () => ({ success: true, ...result, next_url: '/mission' }) };
    }
  });
  async function advance(milliseconds) {
    // One first frame establishes the clock, as in a newly visible browser tab.
    if (now === 0 && frames.size) {
      const callbacks = [...frames.values()]; frames.clear();
      callbacks.forEach(callback => callback(now));
    }
    const target = now + milliseconds;
    while (now < target) {
      now = Math.min(target, now + 50);
      const callbacks = [...frames.values()]; frames.clear();
      callbacks.forEach(callback => callback(now));
      await Promise.resolve();
    }
    // Flush fetch/json and controller continuations without inventing more frames.
    for (let index = 0; index < 6; index++) await Promise.resolve();
  }
  return { node, document, window, music, cues, bursts, requests, saved, advance,
    key: key => document.dispatch('keydown', { key, preventDefault() {} }) };
}

test('steering sounds only when the car changes lane, not at an edge or during the input delay', async () => {
  const f = fixture();
  assert.deepEqual(f.music, []);
  await f.node('[data-drive-start]').click();
  assert.equal(f.music.at(-1), true);
  await f.key('ArrowLeft');
  await f.key('ArrowLeft');
  await f.key('ArrowRight');
  assert.deepEqual(f.cues, ['turn']);
  await f.advance(150);
  await f.node('[data-drive-right]').click();
  assert.deepEqual(f.cues, ['turn', 'turn']);
  await f.node('[data-drive-pause]').click();
  await f.key('ArrowRight');
  assert.deepEqual(f.cues, ['turn', 'turn']);
  assert.equal(f.music.at(-1), false);
});

test('each collision sounds once, then the saved defeat stops music and plays the loss cue', async () => {
  const f = fixture({ obstacles: [200, 400, 600].map(at_ms => ({ at_ms, lane: 1 })) });
  await f.node('[data-drive-start]').click();
  await f.advance(250);
  assert.deepEqual(f.cues, ['crash']);
  await f.advance(450);
  assert.deepEqual(f.cues, ['crash', 'crash', 'crash', 'lose']);
  assert.equal(f.music.at(-1), false);
  assert.equal(f.node('[data-drive-next]').hidden, false);
  assert.equal(f.requests.filter(request => request.url === '/drive/finish').length, 1);
  assert.ok(f.bursts.every(effect => effect.sound === false));
  await f.advance(1000);
  assert.equal(f.cues.filter(cue => cue === 'lose').length, 1);
});

test('crossing the finish line stops the track and triggers victory applause only after saving succeeds', async () => {
  const f = fixture({ finishFailures: 1 });
  await f.node('[data-drive-start]').click();
  await f.advance(24000);
  assert.equal(f.music.at(-1), false);
  assert.deepEqual(f.cues, []);
  assert.equal(f.node('[data-drive-retry]').hidden, false);
  await f.node('[data-drive-retry]').click();
  assert.deepEqual(f.cues, ['win']);
  assert.equal(f.node('[data-drive-title]').textContent, 'Штит је твој!');
  assert.equal(f.bursts.filter(effect => effect.kind === 'victory').length, 1);
  assert.equal(f.bursts[0].sound, false);
  assert.equal(f.requests.at(-1).body.elapsed_ms, 24000);
});

test('tab hiding and back navigation pause music; resuming requires a tap and skipping stops it', async () => {
  const f = fixture();
  await f.node('[data-drive-start]').click();
  await f.advance(150);
  f.document.hidden = true;
  await f.document.dispatch('visibilitychange');
  assert.equal(f.music.at(-1), false);
  assert.equal(f.node('[data-drive-resume]').hidden, false);
  f.document.hidden = false;
  await f.document.dispatch('visibilitychange');
  assert.equal(f.music.at(-1), false);
  await f.node('[data-drive-resume]').click();
  assert.equal(f.music.at(-1), true);
  await f.window.dispatch('pagehide', { persisted: true });
  assert.equal(f.music.at(-1), false);
  assert.equal(f.node('[data-drive-resume]').hidden, false);
  await f.node('[data-drive-resume]').click();
  assert.equal(f.music.at(-1), true);
  await f.node('[data-drive-skip]').dispatch('submit');
  assert.equal(f.music.at(-1), false);
  assert.equal(f.saved.size, 0);
  await f.advance(500);
  assert.equal(f.requests.length, 1);
});

test('refreshing a saved result stays silent and a restored active drive waits for resume', async () => {
  for (const status of ['won', 'lost', 'skipped']) {
    const f = fixture({ initial: { status, elapsed_ms: status === 'won' ? 24000 : 500, hits: status === 'lost' ? 3 : 0 } });
    assert.deepEqual(f.cues, []);
    assert.deepEqual(f.bursts, []);
    assert.equal(f.music.at(-1), false);
    assert.equal(f.node('[data-drive-next]').hidden, false);
    assert.equal(f.requests.length, 0);
  }
  const f = fixture({ initial: { status: 'active' } });
  assert.equal(f.music.at(-1), false);
  assert.deepEqual(f.cues, []);
  await f.node('[data-drive-resume]').click();
  assert.equal(f.music.at(-1), true);
  assert.equal(f.requests.length, 0);
});
