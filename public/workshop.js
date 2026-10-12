/* Local alphabet controls; the mission button still resumes the real mission. */
(() => {
  const discovery = document.querySelector('[data-alphabet-discovery]');
  if (!discovery) return;
  const search = discovery.querySelector('[data-alphabet-search]');
  const clear = discovery.querySelector('[data-alphabet-clear]');
  const cards = [...discovery.querySelectorAll('[data-alphabet-card]')];
  const caseButtons = [...discovery.querySelectorAll('[data-alphabet-case]')];
  const resultCount = discovery.querySelector('[data-alphabet-count]');
  const empty = discovery.querySelector('[data-alphabet-empty]');
  const normalize = value => value.normalize('NFKC').toLocaleLowerCase('sr').trim();

  function filterLetters() {
    const query = normalize(search.value);
    let visible = 0;
    cards.forEach(card => {
      const matches = [...query].length === 1
        ? normalize(card.querySelector('.letter-upper').textContent) === query
        : normalize(card.dataset.alphabetFind).includes(query);
      card.hidden = query !== '' && !matches;
      if (!card.hidden) visible += 1;
    });
    clear.hidden = !query;
    empty.hidden = visible > 0;
    resultCount.textContent = query ? `Приказано: ${visible} од ${cards.length} слова` : 'Сва слова су ту.';
  }

  function showAll() {
    search.value = '';
    filterLetters();
    search.focus({ preventScroll: true });
  }

  function chooseCase(mode) {
    if (!['pair', 'upper', 'lower'].includes(mode)) return;
    discovery.dataset.letterCase = mode;
    caseButtons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.alphabetCase === mode)));
    cards.forEach(card => {
      const glyph = card.querySelector('.alphabet-glyph');
      const upper = glyph.querySelector('.letter-upper').textContent;
      const lower = glyph.querySelector('.letter-lower').textContent;
      glyph.setAttribute('aria-label', mode === 'upper' ? `Велико ${upper}` : mode === 'lower' ? `Мало ${lower}` : `Велико ${upper}, мало ${lower}`);
      const word = card.querySelector('[data-alphabet-word]');
      word.textContent = mode === 'upper' ? word.dataset.wordUpper : word.dataset.wordLower;
    });
  }

  search.addEventListener('input', filterLetters);
  search.addEventListener('search', filterLetters);
  clear.addEventListener('click', showAll);
  discovery.querySelector('[data-alphabet-show-all]').addEventListener('click', showAll);
  caseButtons.forEach(button => button.addEventListener('click', () => chooseCase(button.dataset.alphabetCase)));
  chooseCase('pair');
  filterLetters();
})();

/* Local dinosaur interactions, with optional synthesized sound. */
import { burst } from './fx.js';

const hatchedEgg = document.querySelector('[data-egg-hatched]');
if (hatchedEgg) burst({ kind: 'unlock', origin: hatchedEgg.querySelector('.egg-art'), label: 'НОВИ ДРУГАР!' });

(() => {
  const hangar = document.querySelector('[data-dino-hangar]');
  if (!hangar) return;
  const stage = hangar.querySelector('[data-dino-stage]');
  const message = hangar.querySelector('[data-dino-message]');
  const buttons = [...hangar.querySelectorAll('[data-dino-reaction]')];
  const reactionNames = ['roar', 'dance', 'power'];
  const messages = {
    roar: ['Рррр! Идемо, екипо!', 'Рррр! То је твој Клик!', 'Дино-поздрав!'],
    dance: ['Лево, десно, скок!', 'Играј са Кликом!', 'То, екипо!'],
    power: ['Супермоћ укључена!', 'Пуууњееење… Спреман!', 'Бам! Дино-моћ!']
  };
  let timer;
  let audio;
  let lastReaction = '';
  let lastReactionAt = 0;
  const voices = new Set();
  const friendButtons = [...hangar.querySelectorAll('[data-rescued-friend]')];
  const friendMessage = hangar.querySelector('[data-friend-message]');
  let friendTimer;
  const muted = () => {
    const toggle = document.querySelector('.sound-toggle');
    if (toggle) return toggle.getAttribute('aria-pressed') === 'true';
    try { return localStorage.getItem('cirilo-muted') === 'true'; } catch { return false; }
  };

  function stopSound() {
    for (const oscillator of voices) { try { oscillator.stop(); } catch { /* Already finished. */ } }
    voices.clear();
  }

  function playSound(reaction) {
    if (muted()) return;
    try {
      const Audio = window.AudioContext || window.webkitAudioContext;
      if (!Audio) return;
      audio ||= new Audio();
      if (audio.state === 'suspended') audio.resume().catch(() => {});
      stopSound();
      const notes = reaction === 'dance' ? [392, 523.25, 659.25, 523.25, 783.99] : (reaction === 'power' ? [261.63, 392, 523.25, 783.99] : [146.83, 174.61, 130.81]);
      notes.forEach((frequency, index) => {
        const oscillator = audio.createOscillator();
        const gain = audio.createGain();
        const at = audio.currentTime + index * (reaction === 'dance' ? .14 : .12);
        oscillator.type = reaction === 'roar' ? 'triangle' : 'sine';
        oscillator.frequency.setValueAtTime(frequency, at);
        if (reaction === 'roar') oscillator.frequency.exponentialRampToValueAtTime(frequency * .7, at + .23);
        gain.gain.setValueAtTime(0, at);
        gain.gain.linearRampToValueAtTime(.055, at + .025);
        gain.gain.exponentialRampToValueAtTime(.001, at + .25);
        oscillator.connect(gain); gain.connect(audio.destination);
        voices.add(oscillator);
        oscillator.onended = () => { voices.delete(oscillator); oscillator.disconnect(); gain.disconnect(); };
        oscillator.start(at); oscillator.stop(at + .27);
      });
    } catch { /* Animation and text remain available without sound. */ }
  }

  function react(reaction, withSound = true) {
    if (!reactionNames.includes(reaction)) return;
    const now = performance.now();
    if (now - lastReactionAt < 350 && lastReaction === reaction) return;
    lastReactionAt = now;
    lastReaction = reaction;
    clearTimeout(timer);
    stage.classList.remove(...reactionNames.map(name => `dino-reacting--${name}`));
    buttons.forEach(button => button.classList.remove('is-active'));
    // Restart a short reaction even when the same button is pressed twice.
    void stage.offsetWidth;
    stage.classList.add(`dino-reacting--${reaction}`);
    buttons.filter(button => button.dataset.dinoReaction === reaction).forEach(button => button.classList.add('is-active'));
    const options = messages[reaction];
    message.classList.remove('is-greeting');
    message.textContent = options[Math.floor(Math.random() * options.length)];
    if (withSound) playSound(reaction);
    burst({
      kind: !withSound ? 'unlock' : reaction === 'dance' ? 'dance' : 'power',
      origin: stage,
      label: reaction === 'roar' ? 'РРРР!' : undefined,
      sound: false
    });
    timer = window.setTimeout(() => {
      stage.classList.remove(...reactionNames.map(name => `dino-reacting--${name}`));
      buttons.forEach(button => button.classList.remove('is-active'));
    }, reaction === 'dance' ? 2500 : 1800);
  }

  buttons.forEach(button => button.addEventListener('click', () => react(button.dataset.dinoReaction)));
  friendButtons.forEach(button => button.addEventListener('click', () => {
    clearTimeout(friendTimer);
    friendButtons.forEach(friend => friend.classList.remove('is-greeting'));
    void button.offsetWidth;
    button.classList.add('is-greeting');
    if (friendMessage) {
      friendMessage.textContent = button.dataset.friendGreeting;
      friendMessage.classList.add('is-greeting');
    }
    burst({ kind: 'answer', origin: button, label: button.dataset.friendCheer });
    friendTimer = setTimeout(() => button.classList.remove('is-greeting'), 1900);
  }));
  document.querySelector('.sound-toggle')?.addEventListener('click', () => setTimeout(() => { if (muted()) stopSound(); }, 0));
  document.addEventListener('visibilitychange', () => { if (document.hidden) stopSound(); });
  window.addEventListener('pagehide', stopSound);
  if (Number(hangar.dataset.newPart) > 0) react('power', false);
})();
