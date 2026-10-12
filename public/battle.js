/* The server resolves and saves every turn. This file only presents the result. */
import { burst } from './fx.js';

(() => {
  const root = document.querySelector('[data-battle]');
  if (!root) return;
  const $ = selector => root.querySelector(selector);
  const $$ = selector => [...root.querySelectorAll(selector)];
  let state;
  try { state = JSON.parse($('[data-battle-state]').textContent); } catch { return; }
  const moveNames = { attack: 'Удар', guard: 'Штит', feint: 'Варка', dodge: 'Ракетни скок' };
  const moveActions = { attack: 'is-attacking', guard: 'is-guarding', feint: 'is-feinting', dodge: 'is-dodging' };
  const animationClasses = ['is-attacking', 'is-guarding', 'is-feinting', 'is-hit', 'is-dodging'];
  const moveButtons = $$('[data-battle-move]');
  const powerButtons = $$('[data-battle-power]');
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let busy = false;
  let audio;
  let requestController;
  const oscillators = new Set();
  const delay = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

  function soundIsMuted() {
    const toggle = document.querySelector('.sound-toggle');
    if (toggle) return toggle.getAttribute('aria-pressed') === 'true';
    try { return localStorage.getItem('cirilo-muted') === 'true'; } catch { return false; }
  }

  function stopSound() {
    for (const oscillator of oscillators) { try { oscillator.stop(); } catch { /* It has already ended. */ } }
    oscillators.clear();
  }

  function sound(kind) {
    // The context is opened by the move button, never by a delayed result or reload.
    if (soundIsMuted() || document.hidden || audio?.state !== 'running') return;
    try {
      stopSound();
      const notes = kind === 'victory' ? [523.25, 659.25, 783.99, 1046.5]
        : kind === 'defeat' ? [261.63, 220, 164.81]
        : kind === 'win' ? [440, 659.25] : kind === 'lose' ? [220, 174.61] : [392, 392];
      const descending = kind === 'lose' || kind === 'defeat';
      const duration = kind === 'defeat' ? .34 : .26;
      notes.forEach((frequency, index) => {
        const oscillator = audio.createOscillator();
        const gain = audio.createGain();
        const at = audio.currentTime + index * (kind === 'defeat' ? .18 : .12);
        oscillator.type = descending ? 'triangle' : 'sine';
        oscillator.frequency.setValueAtTime(frequency, at);
        gain.gain.setValueAtTime(0, at);
        gain.gain.linearRampToValueAtTime(.055, at + .02);
        gain.gain.exponentialRampToValueAtTime(.001, at + duration - .02);
        oscillator.connect(gain); gain.connect(audio.destination);
        oscillators.add(oscillator);
        oscillator.onended = () => { oscillators.delete(oscillator); oscillator.disconnect(); gain.disconnect(); };
        oscillator.start(at); oscillator.stop(at + duration);
      });
    } catch { /* All feedback is also visible. */ }
  }

  function putIcon(target, name, kind = 'move') {
    if (!target) return;
    const template = $(`[data-${kind}-template="${name}"]`);
    target.replaceChildren();
    if (template) target.append(template.content.cloneNode(true));
  }

  function setBusy(value) {
    busy = value;
    root.setAttribute('aria-busy', String(value));
    moveButtons.forEach(button => { button.disabled = value || state.status !== 'active'; });
    powerButtons.forEach(button => { button.disabled = value || !state.powers?.[button.dataset.battlePower]?.available; });
    $('[data-result-strip]').classList.toggle('is-waiting', value);
    if (!value) moveButtons.forEach(button => button.classList.remove('is-picked'));
  }

  function clearAnimations() {
    $$('[data-fighter]').forEach(fighter => fighter.classList.remove(...animationClasses));
    $$('[data-status]').forEach(status => status.classList.remove('is-damaged'));
    $$('.heart-pip.is-lost, .armor-pip.is-lost').forEach(pip => pip.classList.remove('is-lost'));
    $$('[data-falling-gear]').forEach(slot => { slot.classList.remove('is-falling'); slot.replaceChildren(); });
  }

  function health(side, current) {
    return side === 'player'
      ? { hearts: Number(current.base_hp), armor: Number(current.armor_remaining) }
      : { hearts: Math.min(Number(current.enemy_hp), 3), armor: Math.max(Number(current.enemy_hp) - 3, 0) };
  }

  function updateHealth(side, next) {
    const player = side === 'player';
    const { hearts, armor } = health(side, next);
    const maxArmor = player ? Number(next.gear_count) : Math.max(Number(next.enemy_max_hp) - 3, 0);
    const heartRow = $(`[data-hearts="${side}"]`);
    [...heartRow.children].forEach((pip, index) => pip.classList.toggle('is-full', index < hearts));
    heartRow.setAttribute('aria-label', `${hearts} од 3 срца`);
    $(`[data-armor-count="${side}"]`).textContent = armor;
    const armorRow = $(`[data-armor="${side}"]`);
    [...armorRow.children].forEach((pip, index) => pip.classList.toggle('is-full', index < armor));
    armorRow.setAttribute('aria-label', `${armor} од ${maxArmor} делова оклопа`);
    const noArmor = $(`[data-no-armor="${side}"]`);
    if (noArmor) noArmor.hidden = armor > 0;
  }

  function showHealthLoss(side, previous, next) {
    const before = health(side, previous), after = health(side, next);
    for (const kind of ['hearts', 'armor']) {
      [...$(`[data-${kind}="${side}"]`).children].forEach((pip, index) => {
        if (index >= after[kind] && index < before[kind]) pip.classList.add('is-lost');
      });
    }
  }

  function updateSprites(next) {
    // These SVG strings come from the same-origin Rails helpers; they contain no user markup.
    for (const side of ['player', 'enemy']) {
      const svg = next[`${side}_svg`];
      if (typeof svg === 'string' && svg.trimStart().startsWith('<svg')) $(`[data-sprite="${side}"]`).innerHTML = svg;
    }
  }

  function updateResult(next) {
    const hasMoves = !next.pending_power && moveNames[next.player_move] && moveNames[next.enemy_move];
    $('[data-round-matchup]').hidden = !hasMoves;
    const strip = $('[data-result-strip]');
    strip.classList.remove('is-win', 'is-lose', 'is-tie', 'is-blocked', 'is-dodge');
    if (next.pending_power) {
      $('[data-result-title]').textContent = next.pending_power === 'goggles' ? 'Наочаре су откриле потез!' : 'Светлосни штит је укључен!';
      $('[data-result-detail]').textContent = next.pending_power === 'goggles'
        ? `Мргуд бира: ${moveNames[next.revealed_enemy_move]}. Сада бираш ти!`
        : 'Изабери потез. Штит те чува.';
      return;
    }
    if (next.outcome) strip.classList.add(`is-${next.outcome}`);
    if (hasMoves) {
      putIcon($('[data-round-player]'), next.player_move);
      putIcon($('[data-round-enemy]'), next.enemy_move);
      $('[data-round-symbol]').textContent = next.outcome === 'win' ? '›' : next.outcome === 'lose' ? '‹' : '=';
      $('[data-result-title]').textContent = { win: 'Клик погађа!', lose: 'Мргуд погађа.', tie: 'Исто! Нико није погођен.', blocked: 'Штит је сачувао Клика!', dodge: 'Хоп! Клик је избегао потез.' }[next.outcome] || 'Додирни један потез.';
      const victim = next.outcome === 'win' ? 'Мргуд' : 'Клик';
      const remainingHp = Number(next.outcome === 'win' ? next.enemy_hp : next.player_hp);
      $('[data-result-detail]').textContent = ['blocked', 'dodge'].includes(next.outcome) ? next.feedback : next.outcome === 'tie' ? 'Пробај други потез!' : `${victim} губи ${remainingHp >= 3 ? 'део оклопа' : 'срце'}.`;
      for (const side of ['player', 'enemy']) {
        const bubble = $(`[data-move-bubble="${side}"]`);
        putIcon(bubble, next[`${side}_move`]);
        bubble.hidden = false;
      }
    }
  }

  function updatePowers(next) {
    const revealed = next.revealed_enemy_move;
    $('[data-revealed-move]').hidden = !revealed;
    $('[data-revealed-name]').textContent = moveNames[revealed] || '';
    putIcon($('[data-revealed-icon]'), revealed);
    $('[data-shield-ready]').hidden = !next.shield_armed;
    powerButtons.forEach(button => {
      const power = button.dataset.battlePower;
      const status = next.powers?.[power] || {};
      const label = $(`[data-power-status="${power}"]`);
      if (label) label.textContent = status.armed ? 'Штит укључен' : status.used ? 'Искоришћено' : '1×';
      const card = $(`[data-power-card="${power}"]`);
      card?.classList.toggle('is-locked', !status.owned);
      card?.classList.toggle('is-used', !!status.used);
      card?.classList.toggle('is-armed', !!status.armed);
      button.disabled = busy || !status.available;
    });
  }

  function showFinale(next, announce = false) {
    const finished = next.status !== 'active';
    const won = next.status === 'won';
    root.classList.toggle('is-completed', finished);
    $('[data-active-battle]').hidden = finished;
    $('[data-result-strip]').hidden = finished;
    const finale = $('[data-battle-finale]');
    finale.hidden = !finished;
    if (!finished) return;
    finale.classList.toggle('is-victory', won);
    finale.classList.toggle('is-defeat', !won);
    putIcon($('[data-final-medal]'), won ? 'medal' : 'guard');
    $('[data-final-kicker]').textContent = won ? 'БРАВО, КЛИК!' : 'КРАЈ БОРБЕ';
    $('[data-final-title]').textContent = won ? 'Победа!' : 'Мргуд је победио.';
    $('[data-final-detail]').textContent = won ? 'Медаља је твоја!' : 'Нова мисија, нова шанса!';
    $(`[data-fighter="${won ? 'enemy' : 'player'}"]`).classList.add('is-knocked-out');
    if (announce) {
      $('[data-battle-live]').textContent = `${won ? 'Победа! Клик је освојио медаљу.' : 'Мргуд је победио. Нова мисија, нова шанса!'} Сви твоји делови су сачувани.`;
      const heading = $('[data-final-title]');
      heading.setAttribute('tabindex', '-1');
      heading.focus({ preventScroll: true });
      // Move the result into view before starting effects, including on a short phone screen.
      finale.scrollIntoView({ block: 'center', behavior: 'instant' });
    }
  }

  function applyState(next, announce = false) {
    state = next;
    $('[data-battle-round]').textContent = state.status === 'active' ? Number(state.round) + 1 : state.round;
    $('[data-choice-prompt]').textContent = 'Изабери потез';
    updateHealth('player', next);
    updateHealth('enemy', next);
    updateSprites(next);
    updateResult(next);
    updatePowers(next);
    showFinale(next, announce);
    moveButtons.forEach(button => { button.disabled = busy || state.status !== 'active'; });
  }

  function errorMessage(text) {
    $('[data-battle-error-text]').textContent = text;
    $('[data-battle-error]').hidden = false;
  }

  function dropGear(side, previous, next) {
    const slot = $(`[data-falling-gear="${side}"]`);
    if (side === 'player') {
      const lost = next.dropped_part;
      if (!lost || Number(previous.armor_remaining) <= Number(next.armor_remaining)) return;
      const position = Number(lost.position);
      if (Number.isInteger(position) && position > 0 && position <= 16) putIcon(slot, position, 'part');
      else putIcon(slot, 'crystal');
    } else {
      if (Number(previous.enemy_hp) <= 3) return;
      putIcon(slot, 'guard');
    }
    slot.classList.add('is-falling');
  }

  async function animateTurn(previous, next) {
    clearAnimations();
    $('[data-result-strip]').classList.remove('is-waiting');
    updateResult(next);
    const fast = reducedMotion.matches || document.hidden;
    for (const side of ['player', 'enemy']) {
      const actionClass = moveActions[next[`${side}_move`]];
      if (actionClass) $(`[data-fighter="${side}"]`).classList.add(actionClass);
    }
    if (!fast) await delay(220);
    applyState(next);
    if (next.outcome === 'blocked') $('[data-fighter="player"]').classList.add('is-guarding');
    const victim = next.outcome === 'win' ? 'enemy' : next.outcome === 'lose' ? 'player' : null;
    if (victim && Number(previous[`${victim}_hp`]) > Number(next[`${victim}_hp`])) {
      const fighter = $(`[data-fighter="${victim}"]`);
      fighter.classList.remove(...animationClasses);
      fighter.classList.add('is-hit');
      showHealthLoss(victim, previous, next);
      dropGear(victim, previous, next);
      burst({ kind: 'hit', origin: fighter, label: Number(next[`${victim}_hp`]) >= 3 ? '−1 ОКЛОП' : '−1 СРЦЕ', sound: false });
    }
    sound(next.outcome);
    $('[data-battle-live]').textContent = `Твој потез: ${moveNames[next.player_move]}. Мргудов потез: ${moveNames[next.enemy_move]}. ${next.feedback || ''} Клик: ${next.base_hp} срца и ${next.armor_remaining} оклопа. Мргуд: ${Math.min(next.enemy_hp, 3)} срца и ${Math.max(next.enemy_hp - 3, 0)} оклопа.`;
    await delay(fast ? 120 : 950);
    clearAnimations();
    if (next.status !== 'active') {
      $('[data-battle-arena]').classList.add(next.status === 'won' ? 'is-victory' : 'is-defeat');
      showFinale(next, true);
      $('[data-battle-finale]').classList.add('is-revealing');
      if (next.status === 'won') {
        sound('victory');
        burst({ kind: 'victory', origin: $('[data-final-medal]'), label: 'ПОБЕДА!', sound: false });
      } else sound('defeat');
    }
  }

  async function submitAction(kind, value) {
    const powerAction = kind === 'power';
    if (busy || state.status !== 'active') return;
    if (powerAction ? !state.powers?.[value]?.available : !['attack', 'guard', 'feint'].includes(value)) return;
    const previous = state;
    const selected = $(`[data-battle-${kind}="${value}"]`);
    selected.classList.add('is-picked');
    $('[data-battle-error]').hidden = true;
    setBusy(true);
    $('[data-result-title]').textContent = powerAction ? 'Опрема се укључује…' : 'Један, два… потез!';
    $('[data-result-detail]').textContent = powerAction ? 'Моћ се чува у твојој борби.' : 'Клик и Мргуд откривају своје потезе.';
    $('[data-round-matchup]').hidden = true;
    $$('[data-move-bubble]').forEach(bubble => { bubble.hidden = true; });
    // Prime audio during the actual tap, for mobile browsers with an audio gesture gate.
    if (!soundIsMuted()) {
      try {
        const Audio = window.AudioContext || window.webkitAudioContext;
        if (Audio) { audio ||= new Audio(); if (audio.state === 'suspended') audio.resume().catch(() => {}); }
      } catch { /* Sound is optional. */ }
    }
    requestController = new AbortController();
    const timeout = setTimeout(() => requestController.abort(), 18000);
    try {
      const response = await fetch(powerAction ? root.dataset.powerEndpoint : root.dataset.battleEndpoint, {
        method: 'POST', credentials: 'same-origin', signal: requestController.signal,
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '' },
        body: JSON.stringify({ [kind]: value, expected_round: previous.round, expected_revision: previous.action_revision })
      });
      const payload = await response.json();
      clearTimeout(timeout);
      if (response.status === 409 && payload.state) {
        clearAnimations();
        applyState(payload.state, payload.state.status !== 'active');
        $('[data-battle-live]').textContent = 'Арена је освежена. Сви одиграни потези су сачувани.';
        return;
      }
      if (!response.ok || payload.success === false) throw new Error(payload.error || 'unconfirmed_move');
      if (Number(payload.id) !== Number(previous.id) || !Number.isInteger(payload.round)) throw new Error('invalid_state');
      if (!payload.duplicate && Number(payload.round) > Number(previous.round)) await animateTurn(previous, payload);
      else {
        applyState(payload, payload.status !== 'active');
        if (powerAction && payload.status === 'active') {
          const message = value === 'goggles' && payload.revealed_enemy_move
            ? `Мргуд бира: ${moveNames[payload.revealed_enemy_move]}. Сада бираш ти!`
            : value === 'shield' && payload.shield_armed ? 'Светлосни штит чува први следећи погодак.' : 'Моћ је сачувана. Изабери следећи потез.';
          $('[data-result-title]').textContent = value === 'goggles' ? 'Наочаре су откриле потез!' : 'Моћ је укључена!';
          $('[data-result-detail]').textContent = message;
          $('[data-battle-live]').textContent = message;
          if (value === 'goggles') $('[data-revealed-move]').scrollIntoView({ block: 'nearest', behavior: reducedMotion.matches ? 'instant' : 'smooth' });
        }
      }
    } catch (error) {
      updateResult(state);
      if (!state.player_move) {
        $('[data-result-title]').textContent = 'Потез још није потврђен.';
        $('[data-result-detail]').textContent = 'Пробај поново. Твоја борба је сачувана.';
      }
      errorMessage(error.name === 'AbortError' ? 'Арена чека везу. Пробај поново или освежи приказ.' : 'Потез није потврђен. Пробај поново или освежи арену.');
    } finally {
      clearTimeout(timeout);
      requestController = null;
      setBusy(false);
      selected.classList.remove('is-picked');
      if (state.status === 'active' && document.activeElement === document.body) selected.focus({ preventScroll: true });
    }
  }

  moveButtons.forEach(button => button.addEventListener('click', () => submitAction('move', button.dataset.battleMove)));
  powerButtons.forEach(button => button.addEventListener('click', () => submitAction('power', button.dataset.battlePower)));
  $('[data-battle-refresh]').addEventListener('click', () => window.location.reload());
  document.querySelector('.sound-toggle')?.addEventListener('click', () => setTimeout(() => { if (soundIsMuted()) stopSound(); }, 0));
  document.addEventListener('visibilitychange', () => { if (document.hidden) stopSound(); });
  window.addEventListener('storage', event => { if (event.key === 'cirilo-muted' && event.newValue === 'true') stopSound(); });
  window.addEventListener('pagehide', () => { requestController?.abort(); stopSound(); });
  applyState(state);
})();
