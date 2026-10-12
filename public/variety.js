// These controls only collect an answer. Correctness stays on the server.
export function setupVariety(root, isLocked, onStage = () => {}) {
  const box = root.querySelector('[data-variety]');
  if (!box) return null;
  if (box.dataset.variety === 'repair_word') return setupRepair(box, isLocked, onStage);
  if (box.dataset.variety === 'word_pairs') return setupPairs(box, isLocked, onStage);
  return null;
}

function setupRepair(box, isLocked, onStage) {
  const slots = [...box.querySelectorAll('[data-repair-slot]')];
  const options = [...box.querySelectorAll('[data-repair-letter]')];
  const original = slots.map(slot => slot.dataset.originalLetter);
  const picker = box.querySelector('[data-repair-options]');
  const submit = box.querySelector('[data-submit-variety]');
  const undo = box.querySelector('[data-variety-undo]');
  const status = box.querySelector('[data-variety-status]');
  const display = letter => box.dataset.displayCase === 'lower' ? letter.toLocaleLowerCase('sr') : letter;
  let active = null, replacement = null;
  const complete = () => active !== null && replacement !== null && replacement !== original[active];
  const answer = () => original.map((letter, index) => index === active && replacement !== null ? replacement : letter).join('');

  function refresh() {
    const locked = isLocked(), ready = complete();
    slots.forEach((slot, index) => {
      const letter = index === active && replacement !== null ? replacement : original[index];
      slot.querySelector('span').textContent = display(letter);
      slot.disabled = locked;
      slot.classList.toggle('is-active', index === active);
      slot.classList.toggle('is-changed', index === active && ready);
      slot.setAttribute('aria-pressed', String(index === active));
      slot.setAttribute('aria-label', `${index + 1}. слово: ${display(letter)}${index === active ? ', изабрано' : ''}`);
    });
    picker.hidden = active === null;
    options.forEach(option => {
      option.disabled = locked || active === null;
      option.setAttribute('aria-pressed', String(option.dataset.repairLetter === replacement));
    });
    undo.disabled = locked || active === null;
    submit.disabled = locked || !ready;
    status.textContent = active === null ? 'Пронађи слово које не припада речи.' : ready ? 'Прочитај реч, па је провери.' : 'Изабери ново слово.';
    if (!locked) onStage(ready ? 'check' : 'work');
  }
  slots.forEach((slot, index) => slot.addEventListener('click', () => {
    if (isLocked()) return;
    if (active !== index) replacement = null;
    active = index;
    refresh();
    (options.find(option => option.dataset.repairLetter === replacement) || options[0])?.focus({ preventScroll: true });
  }));
  options.forEach(option => option.addEventListener('click', () => {
    if (isLocked() || active === null) return;
    replacement = option.dataset.repairLetter;
    refresh();
    if (complete()) submit.focus({ preventScroll: true });
  }));
  undo.addEventListener('click', () => {
    if (isLocked()) return;
    const previous = active;
    active = null; replacement = null; refresh();
    slots[previous ?? 0]?.focus({ preventScroll: true });
  });
  refresh();
  return { refresh, lock: refresh, complete, answer };
}

function setupPairs(box, isLocked, onStage) {
  const words = [...box.querySelectorAll('[data-pair-word]')];
  const pictures = [...box.querySelectorAll('[data-pair-picture]')];
  const submit = box.querySelector('[data-submit-variety]');
  const undo = box.querySelector('[data-variety-undo]');
  const status = box.querySelector('[data-variety-status]');
  let pairs = words.map(() => null), active = null;
  const history = [];
  const complete = () => pairs.every(Boolean) && new Set(pairs).size === words.length;
  const answer = () => pairs.map(pair => pair || '').join(',');

  function refresh() {
    const locked = isLocked(), ready = complete();
    words.forEach((word, index) => {
      const label = word.querySelector('[data-pair-label]').textContent;
      word.disabled = locked;
      word.classList.toggle('is-active', index === active);
      word.classList.toggle('is-linked', pairs[index] !== null);
      word.setAttribute('aria-pressed', String(index === active));
      word.setAttribute('aria-label', `${index + 1}. ${label}${pairs[index] ? ', пар је спојен' : ', без пара'}${index === active ? ', изабрано' : ''}`);
    });
    pictures.forEach((picture, index) => {
      const pairedIndex = pairs.indexOf(picture.dataset.pairPicture);
      picture.disabled = locked || active === null;
      picture.classList.toggle('is-linked', pairedIndex !== -1);
      picture.classList.toggle('is-active', active !== null && pairedIndex === active);
      picture.querySelector('[data-pair-badge]').textContent = pairedIndex === -1 ? '·' : String(pairedIndex + 1);
      picture.setAttribute('aria-pressed', String(active !== null && pairedIndex === active));
      picture.setAttribute('aria-label', `Слика ${index + 1}${pairedIndex === -1 ? ', без пара' : `, пар ${pairedIndex + 1}`}`);
    });
    undo.disabled = locked || history.length === 0;
    submit.disabled = locked || !ready;
    const count = pairs.filter(Boolean).length;
    status.textContent = active !== null ? `Изабери слику за ${words[active].querySelector('[data-pair-label]').textContent}.` : ready ? 'Сва три пара су ту. Провери их!' : count ? `Спојено ${count} од ${words.length}. Додирни следећу реч.` : 'Споји све три речи са сликама.';
    if (!locked) onStage(ready ? 'check' : 'work');
  }
  words.forEach((word, index) => word.addEventListener('click', () => {
    if (isLocked()) return;
    active = active === index ? null : index;
    refresh();
    if (active !== null) (pictures.find(picture => picture.dataset.pairPicture === pairs[active]) || pictures[0])?.focus({ preventScroll: true });
  }));
  pictures.forEach(picture => picture.addEventListener('click', () => {
    if (isLocked() || active === null) return;
    const id = picture.dataset.pairPicture;
    if (pairs[active] !== id) {
      history.push([...pairs]);
      // A picture can belong to one word. Reusing it releases its old word.
      pairs = pairs.map((pair, index) => index === active ? id : pair === id ? null : pair);
    }
    active = null;
    refresh();
    focusNext();
  }));
  undo.addEventListener('click', () => {
    if (isLocked() || history.length === 0) return;
    pairs = history.pop(); active = null; refresh(); focusNext();
  });
  function focusNext() {
    const next = pairs.findIndex(pair => pair === null);
    (next === -1 ? submit : words[next]).focus({ preventScroll: true });
  }
  refresh();
  return { refresh, lock: refresh, complete, answer };
}
