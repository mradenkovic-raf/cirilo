import { createTracePad } from './trace_pad.js';

export function setupWordWriting(root, isLocked, onStage = () => {}) {
  const find = selector => root.querySelector(selector);
  const letters = JSON.parse(find('#writing-data').textContent);
  const filling = find('[data-word-writing]').dataset.filling === 'true';
  const slots = [...root.querySelectorAll('[data-writing-slot]')];
  const state = letters.map(letter => ({ choice: filling ? null : letter, paths: [], saved: false, wrong: false }));
  const picker = find('[data-writing-picker]'), options = find('[data-writing-options]');
  const change = find('[data-writing-change]');
  const padBox = find('[data-writing-pad]'), save = find('[data-writing-save]');
  const submit = find('[data-submit-writing]'), notice = find('[data-writing-notice]');
  const clear = find('[data-writing-clear]');
  let active = 0;
  const pad = createTracePad(find('.trace-board'), () => isLocked() || !state[active].choice, () => {
    state[active].paths = pad.paths(); state[active].saved = false; state[active].wrong = false; refresh();
  });

  function refresh() {
    const current = state[active], allSaved = state.every(item => item.saved);
    const written = state.filter(item => item.saved).length;
    slots.forEach((slot, index) => {
      const item = state[index];
      slot.classList.toggle('is-active', index === active);
      slot.classList.toggle('is-written', item.saved);
      slot.classList.toggle('needs-rewrite', item.wrong);
      slot.setAttribute('aria-current', index === active ? 'step' : 'false');
      slot.querySelector('span').textContent = item.choice?.target || '?';
      slot.querySelector('small').textContent = item.wrong ? '↻' : item.saved ? '✓' : letters[index].index + 1;
      slot.setAttribute('aria-label', `Место ${letters[index].index + 1}: ${item.choice?.target || 'слово недостаје'}${item.saved ? ', написано' : item.wrong ? ', понови' : ''}${index === active ? ', сада пишеш' : ''}`);
      slot.disabled = isLocked();
    });
    find('[data-writing-step]').textContent = `${letters[active].index + 1}. место у речи · готово ${written} од ${letters.length}`;
    find('[data-writing-current-letter]').textContent = current.choice?.target || '';
    find('canvas').setAttribute('aria-label', `Пиши ${current.choice?.target || 'изабрано слово'} прстом, оловком или мишем.`);
    save.hidden = allSaved;
    save.disabled = isLocked() || current.saved || !current.choice || !pad.hasStroke() || pad.drawing();
    clear.disabled = isLocked() || !pad.hasInk();
    change.disabled = isLocked();
    change.hidden = !filling || !current.choice || !picker.hidden;
    submit.disabled = isLocked() || !allSaved;
    submit.hidden = !allSaved;
    [...options.children].forEach(button => { button.disabled = isLocked(); });
    if (current.wrong) notice.textContent = filling ? 'Поново изабери слово за ово место, па га напиши.' : 'Ово слово понови. Обриши траг, па напиши поново.';
    else if (allSaved) notice.textContent = 'Сва слова су ту. Провери реч!';
    else if (!current.choice) notice.textContent = 'Изабери слово.';
    else if (current.saved) notice.textContent = 'Изабери следеће празно место.';
    else if (pad.hasStroke() && !pad.drawing()) notice.textContent = 'Готово? Потврди слово.';
    else notice.textContent = 'Прати бројеве и стрелице. Подигни прст између потеза.';
    if (!isLocked()) onStage(allSaved ? 'check' : 'work');
  }
  function show(index) {
    state[active].paths = pad.paths(); active = index;
    const item = state[active], letter = letters[active];
    picker.hidden = !filling || !!item.choice; padBox.hidden = !item.choice; options.replaceChildren();
    if (filling) letter.options.forEach(choice => {
      const button = document.createElement('button'); button.type = 'button';
      button.className = 'letter-tile'; button.textContent = choice.target;
      button.setAttribute('aria-label', `Изабери слово ${choice.target}`);
      button.setAttribute('aria-pressed', String(choice.target === item.choice?.target));
      button.addEventListener('click', () => {
        if (isLocked()) return;
        if (item.choice?.target !== choice.target) {
          item.choice = choice; item.paths = []; item.saved = false; item.wrong = false;
        }
        picker.hidden = true; padBox.hidden = false; pad.set(choice.paths, item.paths);
        [...options.children].forEach(option => option.setAttribute('aria-pressed', String(option === button)));
        refresh();
        find('canvas').focus({ preventScroll: true });
        requestAnimationFrame(() => padBox.scrollIntoView({ block: 'nearest', behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' }));
      });
      options.append(button);
    });
    pad.set(item.choice?.paths || [], item.paths);
    refresh();
  }
  slots.forEach((slot, index) => slot.addEventListener('click', () => { if (!isLocked()) show(index); }));
  change.addEventListener('click', () => {
    if (isLocked()) return;
    picker.hidden = false; padBox.hidden = true; change.hidden = true;
    notice.textContent = 'Изабери слово.';
    options.querySelector('[aria-pressed="true"]')?.focus({ preventScroll: true });
  });
  clear.addEventListener('click', () => { if (!isLocked()) pad.clear(); });
  save.addEventListener('click', () => {
    if (isLocked()) return;
    const item = state[active]; item.paths = pad.paths();
    if (!item.choice || pad.drawing() || !pad.hasStroke()) {
      notice.textContent = 'Прво напиши цело слово на пољу изнад.'; return;
    }
    item.saved = true; item.wrong = false;
    let next = state.findIndex((entry, index) => index > active && !entry.saved);
    if (next < 0) next = state.findIndex(entry => !entry.saved);
    if (next >= 0) {
      show(next);
      requestAnimationFrame(() => find('.writing-word').scrollIntoView({ block: 'start', behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' }));
    } else refresh();
    if (state.every(entry => entry.saved)) {
      notice.textContent = 'Сва слова су ту. Провери реч!';
      submit.focus({ preventScroll: true });
      submit.scrollIntoView({ block: 'nearest' });
    }
  });
  show(0);
  return {
    complete: () => state.every(item => item.saved),
    payload() {
      return letters.map((letter, index) => {
        const item = state[index];
        // Score on an independent pad-free calculation to preserve current drawing.
        return { index: letter.index, letter: item.choice.target, ...scoreDrawing(item) };
      });
    },
    review(feedback = [], recovery = false) {
      (Array.isArray(feedback) ? feedback : []).forEach(result => {
        const index = letters.findIndex(letter => letter.index === result.index);
        if (index >= 0 && !result.correct) { state[index].saved = false; state[index].wrong = true; }
      });
      const first = state.findIndex(item => item.wrong);
      if (first >= 0 && !recovery) show(first);
      refresh();
      if (recovery) notice.textContent = 'Прво кратка вежба, па се враћаш да допишеш реч.';
    },
    refresh,
    lock: refresh
  };
}

import { scoreTrace } from './trace.js';
function scoreDrawing(item) {
  const result = scoreTrace(item.choice.paths, item.paths);
  return { score: result.score, metrics: {
    coverage: result.coverage, precision: result.precision, points: result.points,
    drawnLength: result.drawnLength, guideLength: result.guideLength
  } };
}
