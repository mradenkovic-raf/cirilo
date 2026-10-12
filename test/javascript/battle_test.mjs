import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

// Execute the real arena controller against a minimal DOM/audio stand-in.
// Layout, actual taps, and viewport scrolling are verified separately in a browser.
const controller = readFileSync(new URL('../../public/battle.js', import.meta.url), 'utf8')
  .replace("import { burst } from './fx.js';", '');
class Element {
  constructor(dataset = {}) {
    this.dataset = dataset; this.attributes = {}; this.listeners = {}; this.children = [];
    this.hidden = false; this.disabled = false; this.textContent = ''; this.scrolls = []; this.addedClasses = [];
    const names = new Set();
    this.classList = {
      contains: name => names.has(name),
      add: (...values) => values.forEach(value => { names.add(value); this.addedClasses.push(value); }),
      remove: (...values) => values.forEach(value => names.delete(value)),
      toggle(name, on = !names.has(name)) { on ? names.add(name) : names.delete(name); }
    };
  }
  setAttribute(name, value) { this.attributes[name] = String(value); }
  getAttribute(name) { return this.attributes[name]; }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  async click() { await Promise.all((this.listeners.click || []).map(callback => callback())); }
  replaceChildren() { this.children = []; }
  focus() { this.focused = true; }
  scrollIntoView(options) { this.scrolls.push(options); }
}
const active = {
  id: 7, status: 'active', round: 0, action_revision: 0,
  base_hp: 3, player_hp: 3, armor_remaining: 0, gear_count: 0,
  enemy_hp: 1, enemy_max_hp: 3, powers: {}
};
function fixture({ outcome = 'won', initial = active, muted = false, duplicate = false, audioAvailable = true, reply = {} } = {}) {
  const nodes = new Map(), bursts = [], notes = [];
  const node = selector => {
    if (!nodes.has(selector)) nodes.set(selector, new Element());
    return nodes.get(selector);
  };
  const root = node('[data-battle]');
  root.dataset = { battleEndpoint: '/battles/7/moves', powerEndpoint: '/battles/7/power' };
  root.querySelector = selector => selector.includes('-template=') ? null : node(selector);
  const moves = ['attack', 'guard', 'feint'].map(move => {
    const button = node(`[data-battle-move="${move}"]`); button.dataset.battleMove = move; return button;
  });
  const groups = {
    '[data-battle-move]': moves, '[data-battle-power]': [],
    '[data-fighter]': ['player', 'enemy'].map(side => node(`[data-fighter="${side}"]`)),
    '[data-status]': ['player', 'enemy'].map(side => node(`[data-status="${side}"]`)),
    '[data-falling-gear]': ['player', 'enemy'].map(side => node(`[data-falling-gear="${side}"]`)),
    '[data-move-bubble]': ['player', 'enemy'].map(side => node(`[data-move-bubble="${side}"]`))
  };
  const healthPips = [];
  root.querySelectorAll = selector => selector === '.heart-pip.is-lost, .armor-pip.is-lost'
    ? healthPips.filter(pip => pip.classList.contains('is-lost')) : groups[selector] || [];
  for (const side of ['player', 'enemy']) {
    const armor = side === 'player' ? initial.gear_count : Math.max(initial.enemy_max_hp - 3, 0);
    for (const [kind, count] of [['hearts', 3], ['armor', armor]]) {
      const pips = Array.from({ length: count }, () => new Element());
      node(`[data-${kind}="${side}"]`).children = pips;
      healthPips.push(...pips);
    }
  }
  node('[data-battle-state]').textContent = JSON.stringify(initial);
  node('.sound-toggle').setAttribute('aria-pressed', String(muted));
  const document = {
    hidden: false, body: new Element(), activeElement: null,
    querySelector: node, addEventListener() {}
  };
  let audioContexts = 0, requests = 0;
  class AudioContext {
    constructor() { audioContexts++; this.state = 'running'; this.currentTime = 0; }
    createOscillator() {
      return { frequency: { setValueAtTime(value) { notes.push(value); } }, connect() {}, disconnect() {}, start() {}, stop() {} };
    }
    createGain() {
      return { gain: { setValueAtTime() {}, linearRampToValueAtTime() {}, exponentialRampToValueAtTime() {} }, connect() {}, disconnect() {} };
    }
  }
  const won = outcome === 'won';
  const response = {
    ...initial, status: outcome, round: 1, action_revision: 1, success: true, duplicate,
    base_hp: won ? 3 : 0, player_hp: won ? 3 : 0, enemy_hp: won ? 0 : 1,
    outcome: won ? 'win' : 'lose', player_move: 'attack', enemy_move: won ? 'feint' : 'guard', ...reply
  };
  runInNewContext(controller, {
    document, window: { AudioContext: audioAvailable ? AudioContext : undefined, matchMedia: () => ({ matches: false }), addEventListener() {} },
    localStorage: { getItem: () => String(muted) }, AbortController,
    setTimeout(callback, milliseconds) { if (milliseconds < 2000) queueMicrotask(callback); return 1; },
    clearTimeout() {}, burst: options => bursts.push(options),
    async fetch() { requests++; return { ok: true, status: 200, json: async () => response }; }
  });
  return { node, moves, bursts, notes, healthPips, get audioContexts() { return audioContexts; }, get requests() { return requests; } };
}

test('winning the last round reveals and focuses the outcome, then celebrates once', async () => {
  const f = fixture();
  await f.moves[0].click();
  assert.equal(f.node('[data-final-title]').textContent, 'Победа!');
  assert.equal(f.node('[data-battle-finale]').hidden, false);
  assert.equal(f.node('[data-final-title]').focused, true);
  assert.equal(f.node('[data-battle-finale]').scrolls.length, 1);
  assert.equal(f.node('[data-active-battle]').hidden, true);
  assert.equal(f.node('[data-result-strip]').hidden, true);
  assert.equal(f.bursts.filter(burst => burst.kind === 'victory').length, 1);
  assert.deepEqual(f.notes.slice(-4), [523.25, 659.25, 783.99, 1046.5]);
  await f.moves[0].click();
  assert.equal(f.requests, 1);
  assert.equal(f.bursts.filter(burst => burst.kind === 'victory').length, 1);
});

test('losing the last round reveals a distinct defeat and plays a descending final cue', async () => {
  const f = fixture({ outcome: 'lost', initial: { ...active, player_hp: 1, base_hp: 1 } });
  await f.moves[0].click();
  assert.equal(f.node('[data-final-title]').textContent, 'Мргуд је победио.');
  assert.equal(f.node('[data-battle-finale]').classList.contains('is-defeat'), true);
  assert.equal(f.node('[data-battle-finale]').scrolls.length, 1);
  assert.equal(f.bursts.filter(burst => burst.kind === 'victory').length, 0);
  assert.deepEqual(f.notes.slice(-3), [261.63, 220, 164.81]);
});

test('mute or unavailable audio preserves the visible final outcome', async () => {
  for (const options of [{ muted: true }, { audioAvailable: false }]) {
    const f = fixture({ outcome: 'lost', ...options });
    await f.moves[0].click();
    assert.equal(f.node('[data-battle-finale]').hidden, false);
    assert.equal(f.node('[data-final-title]').focused, true);
    assert.equal(f.audioContexts, 0);
    assert.deepEqual(f.notes, []);
  }
});

test('refresh and duplicate responses show saved outcomes without replaying celebration or sound', async () => {
  for (const status of ['won', 'lost']) {
    const loaded = fixture({ initial: { ...active, status } });
    assert.equal(loaded.node('[data-battle-finale]').hidden, false);
    assert.equal(loaded.audioContexts, 0);
    assert.equal(loaded.bursts.length, 0);
    assert.equal(loaded.node('[data-battle-finale]').scrolls.length, 0);
    const retried = fixture({ outcome: status, duplicate: true });
    await retried.moves[0].click();
    assert.equal(retried.node('[data-battle-finale]').hidden, false);
    assert.equal(retried.bursts.length, 0);
    assert.deepEqual(retried.notes, []);
    assert.ok([...loaded.healthPips, ...retried.healthPips].every(pip => !pip.addedClasses.includes('is-lost')));
  }
});

test('a hit removes only an armor icon and leaves all three hearts full', async () => {
  for (const side of ['player', 'enemy']) {
    const initial = { ...active, player_hp: 5, armor_remaining: 2, gear_count: 2, enemy_hp: 5, enemy_max_hp: 5 };
    const reply = { ...initial, round: 1, action_revision: 1, outcome: side === 'player' ? 'lose' : 'win', [`${side}_hp`]: 4 };
    if (side === 'player') reply.armor_remaining = 1;
    const f = fixture({ initial, reply });
    await f.moves[0].click();
    const armor = f.node(`[data-armor="${side}"]`).children;
    assert.equal(armor[0].classList.contains('is-full'), true);
    assert.equal(armor[1].classList.contains('is-full'), false);
    assert.deepEqual(f.healthPips.filter(pip => pip.addedClasses.includes('is-lost')), [armor[1]]);
    assert.ok(f.node(`[data-hearts="${side}"]`).children.every(pip => pip.classList.contains('is-full')));
    assert.ok(f.healthPips.every(pip => !pip.classList.contains('is-lost')));
    assert.equal(f.node(`[data-no-armor="${side}"]`).hidden, true);
    assert.equal(f.node('[data-result-detail]').textContent, `${side === 'player' ? 'Клик' : 'Мргуд'} губи део оклопа.`);
    assert.equal(f.bursts.find(burst => burst.kind === 'hit').label, '−1 ОКЛОП');
  }
});

test('the last armor piece disappears before a later hit can remove a heart', async () => {
  for (const side of ['player', 'enemy']) {
    for (const armored of [true, false]) {
      const initial = { ...active, player_hp: armored ? 4 : 3, armor_remaining: armored ? 1 : 0, gear_count: 1, enemy_hp: armored ? 4 : 3, enemy_max_hp: 4 };
      const reply = { ...initial, round: 1, action_revision: 1, outcome: side === 'player' ? 'lose' : 'win', [`${side}_hp`]: armored ? 3 : 2 };
      if (side === 'player') { reply.armor_remaining = 0; reply.base_hp = armored ? 3 : 2; }
      const f = fixture({ initial, reply });
      await f.moves[0].click();
      const lost = f.node(`[data-${armored ? 'armor' : 'hearts'}="${side}"]`).children[armored ? 0 : 2];
      assert.deepEqual(f.healthPips.filter(pip => pip.addedClasses.includes('is-lost')), [lost]);
      assert.equal(f.node(`[data-no-armor="${side}"]`).hidden, false);
      assert.equal(f.node(`[data-armor-count="${side}"]`).textContent, 0);
      assert.equal(f.node('[data-result-detail]').textContent, `${side === 'player' ? 'Клик' : 'Мргуд'} губи ${armored ? 'део оклопа' : 'срце'}.`);
      assert.equal(f.bursts.find(burst => burst.kind === 'hit').label, armored ? '−1 ОКЛОП' : '−1 СРЦЕ');
    }
  }
});

test('ties, shields, dodges, and unchanged health never flash a lost icon', async () => {
  for (const outcome of ['tie', 'blocked', 'dodge', 'win']) {
    const initial = { ...active, player_hp: 4, armor_remaining: 1, gear_count: 1, enemy_hp: 4, enemy_max_hp: 4 };
    const f = fixture({ initial, reply: { ...initial, round: 1, action_revision: 1, outcome } });
    assert.ok(f.healthPips.every(pip => !pip.addedClasses.includes('is-lost')));
    await f.moves[0].click();
    assert.ok(f.healthPips.every(pip => !pip.addedClasses.includes('is-lost')));
    assert.equal(f.bursts.filter(burst => burst.kind === 'hit').length, 0);
    assert.ok(f.healthPips.every(pip => pip.classList.contains('is-full')));
  }
});
