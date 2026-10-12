// Short comic-book celebrations. All content is local and every burst cleans up.
const EFFECTS = {
  stars: { colors: ['#ffd35f', '#ff785d', '#ace96f', '#83d9ef'], accent: '#ffd35f', ink: '#3a4534' },
  lightning: { colors: ['#8cf6ff', '#b59aff', '#fff08c', '#63cde9'], accent: '#8cf6ff', ink: '#35335d' },
  comets: { colors: ['#ffb88a', '#ff82c2', '#baa1ff', '#a4edff'], accent: '#ffad8b', ink: '#513259' }
};
const KINDS = {
  answer: { label: 'СУПЕР!', particles: 16, radius: 155, duration: 1250 },
  mission: { label: 'МИСИЈА УСПЕЛА!', particles: 28, radius: 280, duration: 1800 },
  unlock: { label: 'ОТКЉУЧАНО!', particles: 28, radius: 250, duration: 1900 },
  hit: { label: 'БАМ!', particles: 12, radius: 115, duration: 900 },
  victory: { label: 'ПОБЕДА!', particles: 28, radius: 285, duration: 1900 },
  power: { label: 'ДИНО-МОЋ!', particles: 24, radius: 220, duration: 1600 },
  dance: { label: 'ДИНО-ПЛЕС!', particles: 20, radius: 185, duration: 1500 }
};
const active = new Set();
const voices = new Set();
let audio;
let lastBurstAt = -Infinity;
const clamp = (value, low, high) => Math.min(high, Math.max(low, value));

function muted() {
  const toggle = document.querySelector('.sound-toggle');
  if (toggle) return toggle.getAttribute('aria-pressed') === 'true';
  try { return localStorage.getItem('cirilo-muted') === 'true'; } catch { return false; }
}

function stopSound() {
  for (const oscillator of voices) {
    try { oscillator.stop(); } catch { /* An ended note needs no action. */ }
  }
  voices.clear();
}

function primeAudio() {
  if (muted() || document.hidden) return;
  try {
    const Audio = window.AudioContext || window.webkitAudioContext;
    if (!Audio) return;
    if (!audio || audio.state === 'closed') audio = new Audio();
    if (audio.state === 'suspended') audio.resume().catch(() => {});
  } catch { /* Visual feedback never depends on audio support. */ }
}

function playSound(kind) {
  if (muted() || document.hidden) return;
  primeAudio();
  if (!audio || audio.state !== 'running') return;
  stopSound();
  const notes = ['mission', 'unlock', 'victory'].includes(kind) ? [523.25, 659.25, 783.99, 1046.5] :
    kind === 'hit' ? [180, 105] : kind === 'power' ? [220, 440, 880] :
      kind === 'dance' ? [392, 523.25, 659.25, 523.25] : [659.25, 880];
  try {
    notes.forEach((frequency, index) => {
      const oscillator = audio.createOscillator();
      const gain = audio.createGain();
      const at = audio.currentTime + index * .09;
      oscillator.type = kind === 'hit' ? 'triangle' : 'sine';
      oscillator.frequency.setValueAtTime(frequency, at);
      if (kind === 'hit') oscillator.frequency.exponentialRampToValueAtTime(frequency * .55, at + .13);
      gain.gain.setValueAtTime(0, at);
      gain.gain.linearRampToValueAtTime(.055, at + .015);
      gain.gain.exponentialRampToValueAtTime(.001, at + .24);
      oscillator.connect(gain); gain.connect(audio.destination);
      voices.add(oscillator);
      oscillator.onended = () => { voices.delete(oscillator); oscillator.disconnect(); gain.disconnect(); };
      oscillator.start(at); oscillator.stop(at + .26);
    });
  } catch { stopSound(); }
}

function originPoint(origin, width, height) {
  if (origin && typeof origin.getBoundingClientRect === 'function') {
    const box = origin.getBoundingClientRect();
    if (box.width > 0 && box.height > 0 && box.bottom > 0 && box.top < height && box.right > 0 && box.left < width) {
      return [clamp(box.left + box.width / 2, 70, width - 70),
        clamp(box.top + box.height / 2, 85, height - 85)];
    }
  }
  return [width / 2, height * .43];
}

/**
 * burst({ kind, origin?, label?, sound? }) -> cleanup function.
 * The selected stars/lightning/comets skin is read fresh from body.data-effect.
 * Pass sound:false when the caller already plays its own sound.
 */
export function burst({ kind = 'answer', origin = null, label, sound = true } = {}) {
  const noop = () => {};
  if (!document.body || document.hidden || !Object.hasOwn(KINDS, kind)) return noop;
  const now = performance.now();
  if (now - lastBurstAt < 90) return noop;
  lastBurstAt = now;
  // Repeated taps cannot accumulate unlimited nodes or animations.
  while (active.size >= 2) active.values().next().value();

  const reduced = window.matchMedia?.('(prefers-reduced-motion: reduce)')?.matches || false;
  const skin = Object.hasOwn(EFFECTS, document.body.dataset.effect) ? document.body.dataset.effect : 'stars';
  const palette = EFFECTS[skin], config = KINDS[kind];
  const width = window.innerWidth || document.documentElement.clientWidth;
  const height = window.innerHeight || document.documentElement.clientHeight;
  const [x, y] = originPoint(origin, width, height);
  const stage = document.createElement('div');
  stage.className = `fx-stage fx-${kind} fx-${skin}${reduced ? ' fx-reduced' : ''}`;
  stage.setAttribute('aria-hidden', 'true');
  stage.style.setProperty('--fx-x', `${x}px`);
  stage.style.setProperty('--fx-y', `${y}px`);
  stage.style.setProperty('--fx-accent', palette.accent);
  stage.style.setProperty('--fx-ink', palette.ink);
  stage.style.setProperty('--fx-duration', `${config.duration}ms`);
  const caption = typeof label === 'string' && label.trim() ? label.trim().slice(0, 64) : config.label;

  const badge = document.createElement('div'); badge.className = 'fx-badge';
  const plate = document.createElement('span'); plate.className = 'fx-plate';
  const title = document.createElement('strong'); title.className = 'fx-title'; title.textContent = caption;
  badge.append(plate, title); stage.append(badge);

  if (!reduced) {
    const glow = document.createElement('i'); glow.className = 'fx-glow'; stage.prepend(glow);
    for (let index = 0; index < 2; index++) {
      const ring = document.createElement('i'); ring.className = 'fx-ring';
      ring.style.setProperty('--fx-delay', `${index * 120}ms`);
      stage.append(ring);
    }
    const radius = Math.min(config.radius, width * .66, height * .48);
    for (let index = 0; index < config.particles; index++) {
      const particle = document.createElement('i');
      particle.className = `fx-particle${index % 4 === 0 ? ' fx-spark' : ''}`;
      const angle = (index / config.particles) * Math.PI * 2 + (Math.random() - .5) * .3;
      const reach = radius * (.4 + Math.random() * .65);
      const dx = Math.cos(angle) * reach, dy = Math.sin(angle) * reach;
      particle.style.setProperty('--fx-dx', `${dx.toFixed(1)}px`);
      particle.style.setProperty('--fx-dy', `${dy.toFixed(1)}px`);
      particle.style.setProperty('--fx-fall', `${(dy + 55 + Math.random() * 55).toFixed(1)}px`);
      particle.style.setProperty('--fx-angle', `${(angle * 180 / Math.PI).toFixed(1)}deg`);
      particle.style.setProperty('--fx-spin', `${Math.round(Math.random() * 300 - 150)}deg`);
      particle.style.setProperty('--fx-size', `${Math.round(9 + Math.random() * 15)}px`);
      particle.style.setProperty('--fx-delay', `${Math.round(Math.random() * 85)}ms`);
      particle.style.setProperty('--fx-flight', `${Math.round(config.duration * (.53 + Math.random() * .32))}ms`);
      particle.style.setProperty('--fx-color', palette.colors[index % palette.colors.length]);
      stage.append(particle);
    }
  }

  let timer;
  const cleanup = () => { clearTimeout(timer); stage.remove(); active.delete(cleanup); };
  active.add(cleanup);
  // Native modal dialogs occupy the top layer above every body z-index.
  const host = origin?.closest?.('dialog[open]') || document.body;
  host.append(stage);
  timer = setTimeout(cleanup, reduced ? 850 : config.duration + 150);
  if (sound) playSound(kind);
  return cleanup;
}

function clearEffects() {
  for (const cleanup of [...active]) cleanup();
  stopSound();
}

// Unlock audio during a real gesture, before an answer/shop request returns.
document.addEventListener('pointerdown', primeAudio, { passive: true });
document.addEventListener('keydown', event => { if (['Enter', ' '].includes(event.key)) primeAudio(); });
document.addEventListener('click', event => {
  if (event.target.closest?.('.sound-toggle')) queueMicrotask(() => { if (muted()) stopSound(); });
});
document.addEventListener('visibilitychange', () => { if (document.hidden) clearEffects(); });
window.addEventListener('storage', event => { if (event.key === 'cirilo-muted' && event.newValue === 'true') stopSound(); });
window.addEventListener('pagehide', clearEffects);
