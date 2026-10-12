import test from 'node:test';
import assert from 'node:assert/strict';
import { setupVariety } from '../../public/variety.js';

// A small DOM stand-in exercises the actual controls; page geometry is checked
// separately in a browser. No expected answer is provided to either controller.
class Element {
  constructor(dataset = {}) {
    this.dataset = dataset; this.attributes = {}; this.selectors = {};
    this.listeners = {}; this.disabled = false; this.hidden = false; this.textContent = '';
    const classes = new Set();
    this.classList = {
      contains: name => classes.has(name),
      toggle(name, force = !classes.has(name)) { force ? classes.add(name) : classes.delete(name); }
    };
  }
  querySelector(selector) { return this.selectors[selector] || null; }
  querySelectorAll(selector) { return this.selectors[selector] || []; }
  setAttribute(name, value) { this.attributes[name] = String(value); }
  getAttribute(name) { return this.attributes[name]; }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  click() { for (const callback of this.listeners.click || []) callback({ currentTarget: this }); }
  focus() { Element.currentFocus = this; }
}
function controls(box) {
  const submit = new Element(), undo = new Element(), status = new Element();
  Object.assign(box.selectors, { '[data-submit-variety]': submit, '[data-variety-undo]': undo, '[data-variety-status]': status });
  return { submit, undo, status };
}
function fixture(box) {
  const root = new Element(); root.selectors['[data-variety]'] = box;
  let locked = false;
  const stages = [], controller = setupVariety(root, () => locked, stage => stages.push(stage));
  return { controller, stages, lock(value) { locked = value; controller.refresh(); } };
}
function repairFixture(lower = false) {
  const box = new Element({ variety: 'repair_word', displayCase: lower ? 'lower' : 'upper' });
  const slots = [...'МИТ'].map((letter, index) => {
    const slot = new Element({ repairSlot: String(index), originalLetter: letter });
    slot.selectors.span = new Element(); return slot;
  });
  const options = [...'ШИМА'].map(letter => new Element({ repairLetter: letter }));
  const picker = new Element();
  Object.assign(box.selectors, { '[data-repair-slot]': slots, '[data-repair-letter]': options, '[data-repair-options]': picker });
  return { ...controls(box), ...fixture(box), slots, options, picker };
}
function pairsFixture() {
  const box = new Element({ variety: 'word_pairs' });
  const words = ['МИШ', 'КИТ', 'ПУЖ'].map((label, index) => {
    const word = new Element({ pairWord: `W${index + 1}` });
    const span = new Element(); span.textContent = label;
    word.selectors['[data-pair-label]'] = span; return word;
  });
  const pictures = ['P2', 'P3', 'P1'].map(id => {
    const picture = new Element({ pairPicture: id });
    picture.selectors['[data-pair-badge]'] = new Element(); return picture;
  });
  Object.assign(box.selectors, { '[data-pair-word]': words, '[data-pair-picture]': pictures });
  return { ...controls(box), ...fixture(box), words, pictures };
}

test('repair requires an explicit changed letter and only edits the chosen position', () => {
  const f = repairFixture();
  assert.equal(f.picker.hidden, true); assert.equal(f.submit.disabled, true);
  assert.equal(f.controller.answer(), 'МИТ');
  f.options[0].click(); assert.equal(f.controller.complete(), false);
  f.slots[2].click();
  assert.equal(f.picker.hidden, false); assert.equal(f.submit.disabled, true);
  assert.equal(Element.currentFocus, f.options[0]);
  f.options[0].click();
  assert.equal(f.controller.answer(), 'МИШ'); assert.equal(f.controller.complete(), true);
  assert.equal(f.submit.disabled, false); assert.equal(f.stages.at(-1), 'check');
  assert.equal(Element.currentFocus, f.submit);
  f.slots[0].click();
  assert.equal(f.controller.answer(), 'МИТ'); assert.equal(f.controller.complete(), false);
  assert.equal(f.slots[2].querySelector('span').textContent, 'Т');
  f.options[3].click(); assert.equal(f.controller.answer(), 'АИТ');
  assert.equal(f.slots.filter(slot => slot.classList.contains('is-changed')).length, 1);
});

test('restoring the original letter is incomplete and undo restores the whole original word', () => {
  const f = repairFixture();
  f.slots[1].click(); f.options[1].click();
  assert.equal(f.controller.complete(), false); assert.equal(f.submit.disabled, true);
  f.options[0].click(); assert.equal(f.controller.answer(), 'МШТ');
  f.undo.click();
  assert.equal(f.controller.answer(), 'МИТ'); assert.equal(f.picker.hidden, true);
  assert.equal(f.undo.disabled, true); assert.equal(f.stages.at(-1), 'work');
  assert.equal(Element.currentFocus, f.slots[1]);
});

test('repair displays lowercase but submits uppercase and retains the edited answer across locking', () => {
  const f = repairFixture(true);
  assert.equal(f.slots[0].querySelector('span').textContent, 'м');
  f.slots[2].click(); f.options[0].click(); f.lock(true);
  assert.equal(f.slots[2].querySelector('span').textContent, 'ш');
  assert.equal(f.slots[2].getAttribute('aria-pressed'), 'true');
  assert.equal(f.controller.answer(), 'МИШ'); assert.equal(f.submit.disabled, true);
  assert.ok(f.slots.every(slot => slot.disabled)); assert.ok(f.options.every(option => option.disabled));
  f.slots[0].click(); f.options[3].click(); f.undo.click();
  assert.equal(f.controller.answer(), 'МИШ');
  f.lock(false); assert.equal(f.submit.disabled, false);
});

test('pairing requires a word first and all three distinct pictures before submitting', () => {
  const f = pairsFixture();
  assert.equal(f.submit.disabled, true); assert.ok(f.pictures.every(picture => picture.disabled));
  f.pictures[0].click(); assert.equal(f.controller.answer(), ',,');
  f.words[0].click(); assert.ok(f.pictures.every(picture => !picture.disabled));
  assert.equal(Element.currentFocus, f.pictures[0]);
  f.pictures[1].click();
  assert.equal(f.controller.answer(), 'P3,,'); assert.equal(f.controller.complete(), false);
  assert.equal(f.pictures[1].querySelector('[data-pair-badge]').textContent, '1');
  assert.ok(f.pictures.every(picture => picture.disabled));
  assert.equal(Element.currentFocus, f.words[1]);
  f.words[1].click(); f.pictures[2].click();
  f.words[2].click(); f.pictures[0].click();
  assert.equal(f.controller.answer(), 'P3,P1,P2'); assert.equal(f.controller.complete(), true);
  assert.equal(f.submit.disabled, false); assert.equal(f.stages.at(-1), 'check');
  assert.equal(Element.currentFocus, f.submit);
});

test('reassigning a picture releases its old word and undo restores both connections', () => {
  const f = pairsFixture();
  f.words[0].click(); f.pictures[1].click();
  f.words[1].click(); f.pictures[2].click();
  f.words[2].click(); f.pictures[0].click();
  f.words[1].click(); f.pictures[1].click();
  assert.equal(f.controller.answer(), ',P3,P2'); assert.equal(f.controller.complete(), false);
  assert.equal(f.submit.disabled, true);
  assert.equal(f.words[0].classList.contains('is-linked'), false);
  assert.equal(f.pictures[2].classList.contains('is-linked'), false);
  assert.equal(f.pictures[1].querySelector('[data-pair-badge]').textContent, '2');
  assert.equal(Element.currentFocus, f.words[0]);
  f.undo.click();
  assert.equal(f.controller.answer(), 'P3,P1,P2'); assert.equal(f.controller.complete(), true);
  f.undo.click(); assert.equal(f.controller.answer(), 'P3,P1,');
});

test('pairing can deselect a word and keeps answers while pending or completed', () => {
  const f = pairsFixture();
  f.words[0].click(); f.words[0].click();
  assert.ok(f.pictures.every(picture => picture.disabled));
  f.words[0].click(); f.pictures[1].click();
  f.words[1].click(); f.pictures[2].click();
  f.words[2].click(); f.pictures[0].click();
  f.lock(true);
  assert.ok(f.words.every(word => word.disabled)); assert.ok(f.pictures.every(picture => picture.disabled));
  assert.equal(f.undo.disabled, true); assert.equal(f.submit.disabled, true);
  f.words[0].click(); f.pictures[2].click(); f.undo.click();
  assert.equal(f.controller.answer(), 'P3,P1,P2');
  f.lock(false); assert.equal(f.submit.disabled, false); assert.equal(f.undo.disabled, false);
});
