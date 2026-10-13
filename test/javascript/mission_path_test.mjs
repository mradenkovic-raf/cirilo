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
  const header = new Element(), path = new Element(), dots = new Element(), label = new Element(), drive = new Element();
  header.selectors['[data-mission-path]'] = path;
  header.selectors['[data-mission-label]'] = label;
  path.selectors['[data-mission-dots]'] = dots;
  path.selectors['[data-mission-drive]'] = drive;
  drive.dataset = { step: '6', status: 'upcoming', label: 'Вожња те чека на пола пута.' };
  return { path, dots, label, drive, controller: setupMissionPath(header) };
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

test('the car follows the sixth original task when recovery changes the route and becomes current after the answer', () => {
  const { controller, path, drive } = fixture();
  controller.update({ cursor: 3, total: 12, correct: true });
  assert.equal(drive.style.left, '50%');
  controller.update({ cursor: 3, total: 13, correct: false,
    drive_checkpoint: { step: 7, status: 'upcoming', label: 'Вожња те чека на пола пута.' } });
  assert.equal(drive.style.left, `${7 / 13 * 100}%`);
  assert.equal(drive.dataset.status, 'upcoming');
  controller.update({ cursor: 7, total: 13, correct: true,
    drive_checkpoint: { step: 7, status: 'current', label: 'Време је за вожњу!' } });
  assert.equal(path.style['--mission-position'], drive.style.left);
  assert.equal(drive.dataset.status, 'current');
  assert.match(path.attributes['aria-valuetext'], /Време је за вожњу!/);
});

test('a completed drive keeps its result as later recovery tasks lengthen the route', () => {
  const { controller, path, drive } = fixture();
  for (const status of ['won', 'lost', 'skipped', 'passed']) {
    controller.update({ cursor: 9, total: 13, correct: false,
      drive_checkpoint: { step: 6, status, label: `Резултат: ${status}` } });
    assert.equal(drive.style.left, `${6 / 13 * 100}%`);
    assert.equal(drive.dataset.status, status);
    assert.match(path.attributes['aria-valuetext'], new RegExp(`Резултат: ${status}`));
  }
  controller.update({ cursor: 9, total: 13, correct: true, drive_checkpoint: { step: 99, status: 'won', label: 'bad' } });
  assert.equal(drive.dataset.step, '6');
  assert.equal(drive.dataset.status, 'passed');
});
