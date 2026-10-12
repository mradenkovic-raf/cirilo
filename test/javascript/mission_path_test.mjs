import test from 'node:test';
import assert from 'node:assert/strict';
import { setupMissionPath } from '../../public/mission_path.js';

class Element {
  constructor() {
    this.attributes = {}; this.dataset = {}; this.children = []; this.selectors = {};
    this.style = { setProperty(name, value) { this[name] = value; } };
    const classes = new Set();
    this.classList = {
      contains: name => classes.has(name),
      toggle(name, value) { value ? classes.add(name) : classes.delete(name); }
    };
    this.ownerDocument = { createElement: () => new Element() };
  }
  querySelector(selector) { return this.selectors[selector]; }
  replaceChildren(...children) { this.children = children; }
  setAttribute(name, value) { this.attributes[name] = String(value); }
}

function fixture() {
  const header = new Element(), path = new Element(), dots = new Element(), label = new Element();
  header.selectors['[data-mission-path]'] = path;
  header.selectors['[data-mission-label]'] = label;
  path.selectors['[data-mission-dots]'] = dots;
  return { path, dots, label, controller: setupMissionPath(header) };
}

test('saved progress moves the dinosaur and lights one dot per completed task, including the arena endpoint', () => {
  const { controller, path, dots, label } = fixture();
  controller.update({ cursor: 0, total: 12, correct: false });
  assert.equal(path.style['--mission-position'], '0%');
  assert.equal(dots.children.filter(dot => dot.classList.contains('is-done')).length, 0);
  controller.update({ cursor: 3, total: 12, correct: true });
  assert.equal(path.style['--mission-position'], '25%');
  assert.equal(dots.children.filter(dot => dot.classList.contains('is-done')).length, 3);
  assert.equal(label.textContent, 'Готово 3 / 12');
  controller.update({ cursor: 12, total: 12, correct: true });
  assert.equal(path.style['--mission-position'], '100%');
  assert.ok(dots.children.every(dot => dot.classList.contains('is-done')));
  assert.equal(path.attributes['aria-valuenow'], '12');
});

test('recovery adds a dot without awarding progress and duplicate replies do not move again', () => {
  const { controller, path, dots, label } = fixture();
  controller.update({ cursor: 3, total: 12, correct: true });
  controller.update({ cursor: 3, total: 13, correct: false });
  assert.equal(dots.children.length, 13);
  assert.equal(dots.children.filter(dot => dot.classList.contains('is-done')).length, 3);
  assert.equal(path.attributes['aria-valuenow'], '3');
  assert.equal(path.attributes['aria-valuemax'], '13');
  assert.equal(label.textContent, 'Задатак 4 / 13');
  controller.update({ cursor: 4, total: 13, correct: true });
  const position = path.style['--mission-position'];
  controller.update({ cursor: 4, total: 13, correct: true, duplicate: true });
  assert.equal(path.style['--mission-position'], position);
  assert.equal(dots.children.filter(dot => dot.classList.contains('is-done')).length, 4);
});

test('invalid progress cannot replace the last saved path and pages without a path are supported', () => {
  const { controller, path, dots } = fixture();
  controller.update({ cursor: 5, total: 15, correct: true });
  for (const reply of [{ cursor: 6 }, { cursor: -1, total: 15 }, { cursor: 16, total: 15 }, { cursor: 2.5, total: 15 }]) controller.update(reply);
  assert.equal(path.attributes['aria-valuenow'], '5');
  assert.equal(dots.children.length, 15);
  assert.equal(setupMissionPath(null), null);
});
