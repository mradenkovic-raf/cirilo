// Focused behavior checks with a small DOM/canvas stand-in. These exercise real
// pointer handlers and writing controllers; browser layout is verified separately.
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { createTracePad } from '../../public/trace_pad.js';
import { setupWordWriting } from '../../public/writing.js';

class Element {
  constructor() {
    this.children = []; this.dataset = {}; this.attributes = {}; this.listeners = {};
    this.selectors = {}; this.hidden = false; this.disabled = false; this.textContent = '';
    this.clientWidth = 300;
    const classes = new Set();
    this.classList = {
      add: (...names) => names.forEach(name => classes.add(name)),
      remove: (...names) => names.forEach(name => classes.delete(name)),
      contains: name => classes.has(name),
      toggle(name, force = !classes.has(name)) { force ? classes.add(name) : classes.delete(name); }
    };
  }
  querySelector(selector) { return this.selectors[selector] || null; }
  querySelectorAll(selector) { return this.selectors[selector] || []; }
  setAttribute(name, value) { this.attributes[name] = String(value); }
  getAttribute(name) { return this.attributes[name]; }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  fire(name, attrs = {}) { for (const callback of this.listeners[name] || []) callback({ type: name, pointerId: 1, pointerType: 'pen', button: 0, clientX: 30, clientY: 30, preventDefault() {}, ...attrs }); }
  append(...children) { this.children.push(...children); }
  replaceChildren(...children) { this.children = children; }
  getBoundingClientRect() { return { left: 0, top: 0, width: 300, height: 300 }; }
  setPointerCapture() {}
  focus() {}
  scrollIntoView() {}
}
globalThis.document = { createElement: () => new Element(), createElementNS: () => new Element() };
globalThis.window = { devicePixelRatio: 1, matchMedia: () => ({ matches: true }) };
globalThis.ResizeObserver = class { observe() {} };
globalThis.requestAnimationFrame = callback => callback();

function board() {
  const root = new Element(), canvas = new Element(), guide = new Element();
  canvas.getContext = () => ({ setTransform() {}, beginPath() {}, arc() {}, fill() {}, lineTo() {}, moveTo() {}, stroke() {} });
  root.selectors = { canvas, svg: guide };
  return { root, canvas };
}
const alphabet = JSON.parse(fs.readFileSync(new URL('../../config/alphabet.json', import.meta.url)));
function letter(target, index) {
  const entry = alphabet.find(item => item.upper === target);
  return { target, index, paths: entry.strokes.upper };
}
function draw(canvas, paths) {
  for (const points of paths) {
    canvas.fire('pointerdown', { clientX: points[0][0] * 3, clientY: points[0][1] * 3 });
    for (const point of points.slice(1)) canvas.fire('pointermove', { clientX: point[0] * 3, clientY: point[1] * 3 });
    const last = points.at(-1);
    canvas.fire('pointerup', { clientX: last[0] * 3, clientY: last[1] * 3 });
  }
}
function writingFixture(letters, filling = false, isLocked = () => false) {
  const root = new Element(), pad = board(), controls = {};
  for (const name of ['writing-data', 'word-writing', 'writing-picker', 'writing-options', 'writing-pad', 'writing-save', 'submit-writing', 'writing-notice', 'writing-clear', 'writing-step', 'writing-current-letter', 'writing-change']) {
    const element = new Element(); controls[name] = element;
    root.selectors[name === 'writing-data' ? '#writing-data' : `[data-${name}]`] = element;
  }
  controls['writing-data'].textContent = JSON.stringify(letters);
  controls['word-writing'].dataset.filling = String(filling);
  root.selectors['.trace-board'] = pad.root; root.selectors.canvas = pad.canvas;
  root.selectors['.writing-word'] = new Element();
  const slots = letters.map(() => {
    const slot = new Element(); slot.selectors = { span: new Element(), small: new Element() }; return slot;
  });
  root.selectors['[data-writing-slot]'] = slots;
  const stages = [];
  const controller = setupWordWriting(root, isLocked, stage => stages.push(stage));
  return { controller, controls, slots, canvas: pad.canvas, stages };
}

test('empty or tapped pad cannot become ready; a finished stroke can; erase resets it', () => {
  const fixture = board(); let changes = 0;
  const pad = createTracePad(fixture.root, () => false, () => changes++);
  pad.set(letter('А', 0).paths);
  assert.equal(pad.hasInk(), false); assert.equal(pad.hasStroke(), false);
  fixture.canvas.fire('pointerdown'); assert.equal(pad.drawing(), true);
  fixture.canvas.fire('pointerup'); assert.equal(pad.hasInk(), true); assert.equal(pad.hasStroke(), false);
  draw(fixture.canvas, letter('А', 0).paths);
  assert.equal(pad.drawing(), false); assert.equal(pad.hasStroke(), true); assert.ok(changes >= 4);
  pad.clear(); assert.equal(pad.hasInk(), false); assert.equal(pad.hasStroke(), false);
});

test('whole word requires drawing and finishing every letter before word check', () => {
  const letters = [letter('А', 0), letter('М', 1)];
  const fixture = writingFixture(letters);
  const save = fixture.controls['writing-save'], submit = fixture.controls['submit-writing'];
  assert.equal(save.disabled, true); assert.equal(submit.disabled, true);
  assert.equal(submit.hidden, true);
  draw(fixture.canvas, letters[0].paths);
  assert.equal(save.disabled, false); assert.equal(submit.disabled, true);
  save.fire('click');
  assert.equal(fixture.slots[1].classList.contains('is-active'), true);
  assert.equal(save.disabled, true); assert.equal(fixture.controls['writing-clear'].disabled, true);
  draw(fixture.canvas, letters[1].paths); save.fire('click');
  assert.equal(submit.disabled, false); assert.equal(save.hidden, true);
  assert.equal(submit.hidden, false);
  assert.equal(fixture.controller.complete(), true); assert.equal(fixture.stages.at(-1), 'check');
  assert.deepEqual(fixture.controller.payload().map(item => item.letter), ['А', 'М']);
  assert.ok(fixture.controller.payload().every(item => item.score >= 95));
});

test('erasing one finished letter keeps the other drawing but disables whole-word check', () => {
  const letters = [letter('А', 0), letter('М', 1)], fixture = writingFixture(letters);
  for (const current of letters) { draw(fixture.canvas, current.paths); fixture.controls['writing-save'].fire('click'); }
  fixture.controls['writing-clear'].fire('click');
  assert.equal(fixture.controller.complete(), false);
  assert.equal(fixture.controls['submit-writing'].disabled, true);
  assert.ok(fixture.controller.payload()[0].score >= 95);
  assert.equal(fixture.controller.payload()[1].score, 0);
  assert.equal(fixture.stages.at(-1), 'work');
});

test('missing-letter choice is explicit and server correction never reveals or inserts the answer', () => {
  const target = letter('А', 1), chosen = letter('Б', 1);
  const fixture = writingFixture([{ ...target, options: [target, chosen] }], true);
  assert.equal(fixture.controls['writing-pad'].hidden, true);
  assert.equal(fixture.slots[0].querySelector('span').textContent, '?');
  fixture.controls['writing-options'].children[1].fire('click');
  assert.equal(fixture.controls['writing-pad'].hidden, false);
  assert.equal(fixture.controls['writing-picker'].hidden, true);
  assert.equal(fixture.controls['writing-change'].hidden, false);
  draw(fixture.canvas, chosen.paths); fixture.controls['writing-save'].fire('click');
  assert.equal(fixture.controller.payload()[0].letter, 'Б');
  fixture.controller.review([{ index: 1, correct: false }]);
  assert.equal(fixture.controller.complete(), false);
  assert.equal(fixture.controls['submit-writing'].disabled, true);
  assert.equal(fixture.slots[0].querySelector('span').textContent, 'Б');
  assert.equal(fixture.slots[0].classList.contains('needs-rewrite'), true);
  fixture.controls['writing-change'].fire('click');
  assert.equal(fixture.controls['writing-picker'].hidden, false);
  assert.equal(fixture.controls['writing-pad'].hidden, true);
  assert.equal(fixture.slots[0].querySelector('span').textContent, 'Б');
  fixture.controls['writing-options'].children[0].fire('click');
  assert.equal(fixture.slots[0].querySelector('span').textContent, 'А');
  assert.equal(fixture.controls['writing-save'].disabled, true);
  assert.equal(fixture.controls['submit-writing'].hidden, true);
});

test('pending or completed submission locks editing and restores valid controls when unlocked', () => {
  let locked = false;
  const current = letter('А', 0), fixture = writingFixture([current], false, () => locked);
  draw(fixture.canvas, current.paths);
  locked = true; fixture.controller.refresh();
  assert.equal(fixture.controls['writing-save'].disabled, true);
  assert.equal(fixture.controls['writing-clear'].disabled, true);
  assert.equal(fixture.slots[0].disabled, true);
  const before = fixture.controller.payload()[0].score;
  fixture.controls['writing-clear'].fire('click');
  assert.equal(fixture.controller.payload()[0].score, before);
  locked = false; fixture.controller.refresh();
  assert.equal(fixture.controls['writing-save'].disabled, false);
  assert.equal(fixture.controls['writing-clear'].disabled, false);
});
