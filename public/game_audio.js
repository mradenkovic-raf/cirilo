// Original, locally synthesized music and effects: no downloads or audio service.
// A game requests music with setPlaying(true); the first real gesture unlocks it.
const TRACKS = {
  drive: { step: .16, melody: [76, 79, 81, 79, 76, 74, 72, null, 74, 76, 79, 76, 74, 72, 67, null], bass: [48, 53, 55, 48] },
  arena: { step: .19, melody: [72, null, 76, 79, 74, null, 77, 81, 76, 79, 84, 79, 77, 74, 71, null], bass: [48, 50, 55, 55] }
};
const MAX_VOICES = 28;
const frequency = note => 440 * 2 ** ((note - 69) / 12);

export function createGameAudio(mode) {
  const track = TRACKS[mode] || TRACKS.drive;
  const doc = typeof document === 'undefined' ? null : document;
  const win = typeof window === 'undefined' ? null : window;
  const voices = new Set();
  let context, master, musicBus, effectsBus, noiseBuffer, applauseBuffer;
  let playing = false, unlocked = false, disposed = false, resuming = false, parked = false;
  let timer = null, nextAt = 0, step = 0, lastCue = null, lastCueAt = -Infinity;
  let silent = readMute();

  function readMute() {
    const toggle = doc?.querySelector('.sound-toggle');
    if (toggle) return toggle.getAttribute('aria-pressed') === 'true';
    try { return win?.localStorage?.getItem('cirilo-muted') === 'true'; } catch { return false; }
  }

  function audible() { return !disposed && !parked && unlocked && !silent && !doc?.hidden; }

  function removeVoice(voice) {
    voices.delete(voice);
    voice.source.onended = null;
    try { voice.source.disconnect(); voice.gain.disconnect(); } catch { /* Already disconnected. */ }
  }

  function stopVoices(kind) {
    for (const voice of [...voices]) {
      if (kind && voice.kind !== kind) continue;
      try { voice.source.stop(); } catch { /* The source may already have ended. */ }
      removeVoice(voice);
    }
  }

  function stopMusic() {
    if (timer !== null) clearInterval(timer);
    timer = null;
    stopVoices('music');
  }

  function silenceAll() { stopMusic(); stopVoices(); }

  function sourceVoice(source, at, duration, volume, kind, attack = .008, hold = 0) {
    // Both ended and interrupted sources release their nodes. Repeated taps are bounded.
    while (voices.size >= MAX_VOICES) {
      const oldest = [...voices].find(voice => voice.kind === 'music') || voices.values().next().value;
      try { oldest.source.stop(); } catch { /* Already stopped. */ }
      removeVoice(oldest);
    }
    const gain = context.createGain();
    gain.gain.setValueAtTime(0, at);
    gain.gain.linearRampToValueAtTime(volume, at + attack);
    if (hold) gain.gain.setValueAtTime(volume, at + hold);
    gain.gain.exponentialRampToValueAtTime(.0001, at + duration);
    source.connect(gain);
    gain.connect(kind === 'music' ? musicBus : effectsBus);
    const voice = { source, gain, kind };
    voices.add(voice);
    source.onended = () => removeVoice(voice);
    source.start(at);
    source.stop(at + duration + .025);
  }

  function tone(hz, at, duration, volume, type = 'triangle', endHz = null, kind = 'effect') {
    const source = context.createOscillator();
    source.type = type;
    source.frequency.setValueAtTime(hz, at);
    if (endHz) source.frequency.exponentialRampToValueAtTime(endHz, at + duration);
    sourceVoice(source, at, duration, volume, kind);
  }

  function noise(at, duration, volume) {
    if (!noiseBuffer) {
      noiseBuffer = context.createBuffer(1, Math.ceil(context.sampleRate * .4), context.sampleRate);
      const data = noiseBuffer.getChannelData(0);
      let last = 0;
      for (let index = 0; index < data.length; index++) {
        last = (last + (Math.random() * 2 - 1) * .45) / 1.45;
        data[index] = last;
      }
    }
    const source = context.createBufferSource();
    source.buffer = noiseBuffer;
    sourceVoice(source, at, duration, volume, 'effect', .002);
  }

  function applause(at) {
    if (!applauseBuffer) {
      const duration = 1.85, rate = context.sampleRate;
      applauseBuffer = context.createBuffer(2, Math.ceil(rate * duration), rate);
      // A small crowd of uneven, stereo handclaps. Each clap has three close
      // transients plus a brief room tail, rather than one sustained hiss.
      for (let channel = 0; channel < 2; channel++) {
        const data = applauseBuffer.getChannelData(channel);
        for (let clap = 0; clap < 18; clap++) {
          const start = Math.floor((.025 + clap * .086 + Math.random() * .045) * rate);
          const level = (.24 + Math.random() * .2) * (clap > 12 ? (19 - clap) / 7 : 1);
          for (let sample = 0; sample < rate * .12 && start + sample < data.length; sample++) {
            const t = sample / rate;
            const transient = Math.exp(-t * 110) + (t >= .012 ? .7 * Math.exp(-(t - .012) * 140) : 0) +
              (t >= .026 ? .5 * Math.exp(-(t - .026) * 160) : 0);
            data[start + sample] += (Math.random() * 2 - 1) * level * (transient + .14 * Math.exp(-t * 28));
          }
        }
        for (let sample = 0; sample < data.length; sample++) data[sample] = Math.max(-.85, Math.min(.85, data[sample]));
      }
    }
    const source = context.createBufferSource();
    source.buffer = applauseBuffer;
    sourceVoice(source, at, 1.85, .75, 'effect', .04, 1.35);
  }

  function scheduleMusic() {
    if (!audible() || !playing || context?.state !== 'running') { stopMusic(); return; }
    // No catching up a throttled/background timer with a burst of old notes.
    if (nextAt < context.currentTime) nextAt = context.currentTime + .025;
    while (nextAt < context.currentTime + .18) {
      const note = track.melody[step % track.melody.length];
      if (note !== null) tone(frequency(note), nextAt, track.step * .8, .26, 'triangle', null, 'music');
      if (step % 4 === 0) tone(frequency(track.bass[Math.floor(step / 4) % track.bass.length]), nextAt, track.step * 2.1, .3, 'sine', null, 'music');
      if (step % 2 === 1) tone(130, nextAt, .055, .16, 'sine', 55, 'music');
      nextAt += track.step;
      step++;
    }
  }

  function startMusic() {
    if (!playing || !audible() || context?.state !== 'running' || timer !== null) return;
    nextAt = context.currentTime + .025;
    scheduleMusic();
    timer = setInterval(scheduleMusic, 80);
  }

  function ensureAudio() {
    if (!audible()) return;
    try {
      if (!context) {
        const Audio = win?.AudioContext || win?.webkitAudioContext;
        if (!Audio) return;
        context = new Audio();
        master = context.createGain(); master.gain.value = .34; master.connect(context.destination);
        musicBus = context.createGain(); musicBus.gain.value = .14; musicBus.connect(master);
        effectsBus = context.createGain(); effectsBus.gain.value = .55; effectsBus.connect(master);
        context.onstatechange = () => {
          if (context?.state === 'running') startMusic();
          else stopMusic();
        };
      }
      if (context.state === 'running') startMusic();
      else if (context.state !== 'closed' && !resuming) {
        resuming = true;
        Promise.resolve(context.resume()).then(() => {
          resuming = false;
          if (!audible()) silenceAll();
          else startMusic();
        }).catch(() => { resuming = false; });
      }
    } catch { silenceAll(); }
  }

  function gesture(event) {
    if (event.isTrusted !== true || event.repeat) return;
    unlocked = true;
    ensureAudio();
  }

  function muteChanged() {
    silent = readMute();
    if (silent) silenceAll();
    else ensureAudio();
  }

  function clicked(event) {
    if (event.target.closest?.('.sound-toggle')) queueMicrotask(muteChanged);
  }

  function storageChanged(event) {
    if (event.key !== 'cirilo-muted' && event.key !== null) return;
    // The local button may still show the previous tab's setting.
    silent = event.key === null ? false : event.newValue === 'true';
    if (silent) silenceAll();
    else ensureAudio();
  }

  function suspendAudio() {
    silenceAll();
    if (context?.state === 'running') {
      try {
        Promise.resolve(context.suspend()).then(() => {
          // A rapid app/tab switch can return before suspend() settles.
          if (audible()) ensureAudio();
        }).catch(() => {});
      } catch { /* Mobile audio can be interrupted. */ }
    }
  }

  function visibilityChanged() {
    if (doc.hidden) suspendAudio();
    else ensureAudio();
  }

  function pageHidden(event) {
    if (!event.persisted) { dispose(); return; }
    // Safari and Chromium may restore this exact JS instance on Browser Back.
    // Keep its listeners/context, but silence all sound while it is cached.
    parked = true;
    suspendAudio();
  }

  function pageShown(event) {
    if (!event.persisted || disposed) return;
    parked = false;
    // Another page may have changed mute while this page was in bfcache.
    try { silent = win?.localStorage?.getItem('cirilo-muted') === 'true'; }
    catch { silent = readMute(); }
    ensureAudio();
  }

  function play(cue) {
    if (!audible()) return;
    ensureAudio();
    if (context?.state !== 'running') return;
    const now = context.currentTime;
    if (cue === lastCue && now - lastCueAt < .07) return;
    lastCue = cue; lastCueAt = now;
    try {
      switch (cue) {
        case 'turn': tone(310, now, .09, .17, 'sine', 520); break;
        case 'crash': noise(now, .22, .42); tone(110, now, .25, .34, 'triangle', 45); break;
        case 'hit': noise(now, .075, .32); tone(170, now, .16, .38, 'triangle', 65); tone(740, now + .035, .12, .22); break;
        case 'miss': tone(430, now, .22, .3, 'sine', 150); noise(now, .1, .15); break;
        case 'block': tone(700, now, .24, .24, 'sine'); tone(1050, now + .02, .2, .17, 'sine'); break;
        case 'tie': tone(330, now, .1, .2); tone(330, now + .13, .1, .2); break;
        case 'power': [60, 67, 76].forEach((note, index) => tone(frequency(note), now + index * .07, .2, .3)); break;
        case 'win':
          [72, 76, 79, 84].forEach((note, index) => tone(frequency(note), now + index * .12, .32, .35));
          applause(now + .2);
          break;
        case 'lose': [60, 57, 52].forEach((note, index) => tone(frequency(note), now + index * .2, .33, .29, 'sine')); break;
        default: break;
      }
    } catch { stopVoices('effect'); }
  }

  function setPlaying(value) {
    if (disposed) return;
    playing = Boolean(value);
    if (playing) ensureAudio();
    else stopMusic();
  }

  function dispose() {
    if (disposed) return;
    disposed = true;
    playing = false;
    silenceAll();
    doc?.removeEventListener('pointerdown', gesture, true);
    doc?.removeEventListener('keydown', gesture, true);
    doc?.removeEventListener('click', clicked);
    doc?.removeEventListener('visibilitychange', visibilityChanged);
    win?.removeEventListener('storage', storageChanged);
    win?.removeEventListener('pagehide', pageHidden);
    win?.removeEventListener('pageshow', pageShown);
    if (context) {
      context.onstatechange = null;
      try { master?.disconnect(); musicBus?.disconnect(); effectsBus?.disconnect(); } catch { /* Already disconnected. */ }
      try { Promise.resolve(context.close()).catch(() => {}); } catch { /* Closing an interrupted context is optional. */ }
    }
    noiseBuffer = null; applauseBuffer = null;
  }

  doc?.addEventListener('pointerdown', gesture, { capture: true, passive: true });
  doc?.addEventListener('keydown', gesture, true);
  doc?.addEventListener('click', clicked);
  doc?.addEventListener('visibilitychange', visibilityChanged);
  win?.addEventListener('storage', storageChanged);
  win?.addEventListener('pagehide', pageHidden);
  win?.addEventListener('pageshow', pageShown);
  return { setPlaying, play, dispose };
}
