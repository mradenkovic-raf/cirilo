// User-supplied music is served by this app; effects are synthesized locally.
// A game requests music with setPlaying(true); the first real gesture unlocks it.
const TRACKS = {
  drive: '/audio/bouncy-toy-time.mp3?v=1',
  arena: '/audio/strasni-mrguuud.mp3?v=1'
};
const MAX_VOICES = 28;
const frequency = note => 440 * 2 ** ((note - 69) / 12);

export function createGameAudio(mode) {
  const track = TRACKS[mode] || TRACKS.drive;
  const doc = typeof document === 'undefined' ? null : document;
  const win = typeof window === 'undefined' ? null : window;
  const voices = new Set();
  let context, master, musicBus, effectsBus, noiseBuffer, applauseBuffer;
  let playing = false, unlocked = false, disposed = false, parked = false;
  let resumeSequence = 0, pendingResume = 0;
  let musicBuffer = null, musicSource = null, musicLoading = null, musicRequest = null;
  let musicOffset = 0, musicStartedAt = 0, musicFailed = false;
  let lastCue = null, lastCueAt = -Infinity;
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
    if (!musicSource) return;
    musicOffset = (musicOffset + Math.max(0, context.currentTime - musicStartedAt)) % musicBuffer.duration;
    try { musicSource.stop(); musicSource.disconnect(); } catch { /* Already stopped. */ }
    musicSource = null;
  }

  function silenceAll() { stopMusic(); stopVoices(); }

  function sourceVoice(source, at, duration, volume, kind, attack = .008, hold = 0) {
    // Both ended and interrupted sources release their nodes. Repeated taps are bounded.
    while (voices.size >= MAX_VOICES) {
      const oldest = voices.values().next().value;
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

  function startMusic() {
    if (!playing || !audible() || context?.state !== 'running' || musicSource || musicFailed) return;
    if (!musicBuffer) { loadMusic(); return; }
    try {
      musicSource = context.createBufferSource();
      musicSource.buffer = musicBuffer;
      musicSource.loop = true;
      musicSource.connect(musicBus);
      musicStartedAt = context.currentTime;
      musicSource.start(0, musicOffset);
    } catch { stopMusic(); }
  }

  function loadMusic() {
    if (musicLoading || musicBuffer || musicFailed || disposed || !context || !win?.fetch) return;
    // Decode into the SAME context unlocked by touch/pen release. An HTML audio
    // element started after an async download would need its own mobile gesture.
    musicLoading = (async () => {
      try {
        musicRequest = win.AbortController ? new win.AbortController() : null;
        const response = await win.fetch(track, { signal: musicRequest?.signal, credentials: 'omit' });
        if (!response.ok) throw new Error('Music unavailable');
        const data = await response.arrayBuffer();
        if (disposed) return;
        const buffer = await context.decodeAudioData(data);
        if (disposed) return;
        musicBuffer = buffer;
        startMusic(); // Rechecks playing, mute, visibility and context state.
      } catch {
        // A missing/invalid track must not interrupt gameplay or sound effects.
        // Retry only on a later gesture, not on every render or sound effect.
        musicFailed = true;
      } finally {
        musicLoading = null;
        musicRequest = null;
      }
    })();
  }

  function ensureAudio(activation = false) {
    if (!audible()) return;
    try {
      if (!context) {
        const Audio = win?.AudioContext || win?.webkitAudioContext;
        if (!Audio) return;
        context = new Audio();
        master = context.createGain(); master.gain.value = .34; master.connect(context.destination);
        musicBus = context.createGain(); musicBus.gain.value = .6; musicBus.connect(master);
        effectsBus = context.createGain(); effectsBus.gain.value = .55; effectsBus.connect(master);
        context.onstatechange = () => {
          if (context?.state === 'running') startMusic();
          else stopMusic();
        };
      }
      if (activation) musicFailed = false;
      if (playing) loadMusic();
      if (context.state === 'running') startMusic();
      else if (context.state !== 'closed' && (!pendingResume || activation)) {
        // A blocked mobile resume() can remain pending rather than reject.
        // A fresh user activation must be able to retry that request.
        const request = ++resumeSequence;
        pendingResume = request;
        Promise.resolve(context.resume()).then(() => {
          if (pendingResume === request) pendingResume = 0;
          if (!audible()) silenceAll();
          else startMusic();
        }).catch(() => { if (pendingResume === request) pendingResume = 0; });
      }
    } catch { pendingResume = 0; silenceAll(); }
  }

  function gesture(event) {
    if (event.isTrusted !== true || event.repeat) return;
    // Touch/pen activate browser audio on release; their pointerdown does not.
    if (event.type === 'pointerdown' && event.pointerType !== 'mouse') return;
    if (event.type === 'keydown' && (event.ctrlKey || event.altKey || event.metaKey ||
      ['Escape', 'Shift', 'Control', 'Alt', 'Meta', 'CapsLock', 'NumLock', 'ScrollLock'].includes(event.key))) return;
    unlocked = true;
    ensureAudio(true);
  }

  function muteChanged(activation = false) {
    silent = readMute();
    if (silent) silenceAll();
    else ensureAudio(activation);
  }

  function clicked(event) {
    if (event.target?.closest?.('.sound-toggle')) queueMicrotask(() => muteChanged(event.isTrusted === true));
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
    musicRequest?.abort();
    doc?.removeEventListener('pointerdown', gesture, true);
    doc?.removeEventListener('pointerup', gesture, true);
    doc?.removeEventListener('touchend', gesture, true);
    doc?.removeEventListener('click', gesture, true);
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
    noiseBuffer = null; applauseBuffer = null; musicBuffer = null;
  }

  doc?.addEventListener('pointerdown', gesture, { capture: true, passive: true });
  doc?.addEventListener('pointerup', gesture, { capture: true, passive: true });
  doc?.addEventListener('touchend', gesture, { capture: true, passive: true });
  doc?.addEventListener('click', gesture, true);
  doc?.addEventListener('keydown', gesture, true);
  doc?.addEventListener('click', clicked);
  doc?.addEventListener('visibilitychange', visibilityChanged);
  win?.addEventListener('storage', storageChanged);
  win?.addEventListener('pagehide', pageHidden);
  win?.addEventListener('pageshow', pageShown);
  return { setPlaying, play, dispose };
}
