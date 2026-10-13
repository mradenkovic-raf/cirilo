import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

// Execute the real arena controller against a minimal DOM/audio stand-in.
// Layout, actual taps, and viewport scrolling are verified separately in a browser.
const controller = readFileSync(new URL('../../public/battle.js', import.meta.url), 'utf8')
  .replace(/^import .*;$/gm, '');
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
function fixture({ outcome = 'won', initial = active, muted = false, duplicate = false, audioAvailable = true, reply = {}, replies = [] } = {}) {
  const nodes = new Map(), bursts = [], cues = [], music = [];
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
  const powers = Object.keys(initial.powers || {}).map(power => {
    const button = node(`[data-battle-power="${power}"]`); button.dataset.battlePower = power; return button;
  });
  const groups = {
    '[data-battle-move]': moves, '[data-battle-power]': powers,
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
  let requests = 0;
  const requestBodies = [];
  const won = outcome === 'won';
  const response = {
    ...initial, status: outcome, round: 1, action_revision: 1, success: true, duplicate,
    base_hp: won ? 3 : 0, player_hp: won ? 3 : 0, enemy_hp: won ? 0 : 1,
    outcome: won ? 'win' : 'lose', player_move: 'attack', enemy_move: won ? 'feint' : 'guard', ...reply
  };
  runInNewContext(controller, {
    document, window: { matchMedia: () => ({ matches: false }), addEventListener() {} },
    localStorage: { getItem: () => String(muted) }, AbortController,
    setTimeout(callback, milliseconds) { if (milliseconds < 2000) queueMicrotask(callback); return 1; },
    clearTimeout() {}, burst: options => bursts.push(options),
    createGameAudio(mode) {
      assert.equal(mode, 'arena');
      return {
        setPlaying(value) { music.push(value); },
        play(cue) { if (!muted && audioAvailable) cues.push(cue); },
        dispose() { music.push(false); }
      };
    },
    async fetch(url, options) {
      requests++;
      requestBodies.push(JSON.parse(options.body));
      const next = replies.length ? replies.shift() : response;
      if (next instanceof Error) throw next;
      return { ok: true, status: 200, json: async () => next };
    }
  });
  return { node, moves, powers, bursts, cues, music, healthPips, requestBodies, get requests() { return requests; } };
}

test('goggles visibly reveal the next move, preserve it through a failed move, and expire after playing', async () => {
  const initial = { ...active, enemy_hp: 3, powers: { goggles: { owned: true, available: true, used: false } } };
  const revealed = { ...initial, success: true, round: 0, action_revision: 1, revealed_enemy_move: 'guard', pending_power: 'goggles',
    powers: { goggles: { owned: true, available: false, used: true } } };
  const played = { ...revealed, round: 1, action_revision: 2, pending_power: null, revealed_enemy_move: null,
    enemy_hp: 2, outcome: 'win', player_move: 'feint', enemy_move: 'guard' };
  const f = fixture({ initial, replies: [revealed, new Error('network interrupted'), played] });
  assert.equal(f.node('[data-revealed-move]').hidden, true);
  await f.powers[0].click();
  assert.equal(f.node('[data-revealed-move]').hidden, false);
  assert.equal(f.node('[data-revealed-move]').focused, true);
  assert.equal(f.node('[data-revealed-move]').scrolls[0].block, 'center');
  assert.equal(f.node('[data-revealed-name]').textContent, 'Штит');
  assert.equal(f.node('[data-power-status="goggles"]').textContent, 'Потез откривен');
  assert.equal(f.node('[data-move-bubble="enemy"]').hidden, false);
  assert.equal(f.node('[data-move-bubble="enemy"]').classList.contains('is-revealed'), true);
  assert.equal(f.node('[data-move-bubble="enemy"]').getAttribute('aria-label'), 'Мргудов следећи потез: Штит');
  assert.equal(f.powers[0].disabled, true);
  assert.ok(f.moves.every(button => !button.disabled));
  await f.moves[2].click();
  assert.equal(f.node('[data-revealed-move]').hidden, false);
  assert.equal(f.node('[data-move-bubble="enemy"]').hidden, false);
  assert.equal(f.node('[data-battle-error]').hidden, false);
  assert.equal(f.requestBodies[1].expected_revision, 1);
  await f.moves[2].click();
  assert.equal(f.requestBodies[2].expected_revision, 1);
  assert.equal(f.node('[data-revealed-move]').hidden, true);
  assert.equal(f.node('[data-move-bubble="enemy"]').classList.contains('is-revealed'), false);
  assert.equal(f.node('[data-power-status="goggles"]').textContent, 'Искоришћено');
  assert.equal(f.node('[data-result-title]').textContent, 'Клик погађа!');
  assert.deepEqual(f.cues, ['power', 'hit']);
  assert.equal(f.music.at(-1), true);
});

test('refresh preserves revealed goggles without mistaking the previous round for the next move', () => {
  const f = fixture({ initial: { ...active, round: 4, action_revision: 5,
    player_move: 'attack', enemy_move: 'feint', outcome: 'win',
    powers: { goggles: { owned: true, used: true, available: false } },
    pending_power: 'goggles', revealed_enemy_move: 'guard' } });
  assert.equal(f.node('[data-revealed-name]').textContent, 'Штит');
  assert.equal(f.node('[data-round-matchup]').hidden, true);
  assert.equal(f.node('[data-power-status="goggles"]').textContent, 'Потез откривен');
  assert.equal(f.node('[data-move-bubble="enemy"]').getAttribute('aria-label'), 'Мргудов следећи потез: Штит');
  assert.equal(f.node('[data-revealed-move]').scrolls.length, 0);
  assert.equal(f.requests, 0);
  assert.deepEqual(f.cues, []);
});

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
  assert.deepEqual(f.cues, ['hit', 'win']);
  assert.equal(f.music.at(-1), false);
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
  assert.deepEqual(f.cues, ['miss', 'lose']);
  assert.equal(f.music.at(-1), false);
});

test('mute or unavailable audio preserves the visible final outcome', async () => {
  for (const options of [{ muted: true }, { audioAvailable: false }]) {
    const f = fixture({ outcome: 'lost', ...options });
    await f.moves[0].click();
    assert.equal(f.node('[data-battle-finale]').hidden, false);
    assert.equal(f.node('[data-final-title]').focused, true);
    assert.deepEqual(f.cues, []);

  }
});

test('refresh and duplicate responses show saved outcomes without replaying celebration or sound', async () => {
  for (const status of ['won', 'lost']) {
    const loaded = fixture({ initial: { ...active, status } });
    assert.equal(loaded.node('[data-battle-finale]').hidden, false);
    assert.deepEqual(loaded.cues, []);
    assert.equal(loaded.music.at(-1), false);
    assert.equal(loaded.bursts.length, 0);
    assert.equal(loaded.node('[data-battle-finale]').scrolls.length, 0);
    const retried = fixture({ outcome: status, duplicate: true });
    await retried.moves[0].click();
    assert.equal(retried.node('[data-battle-finale]').hidden, false);
    assert.equal(retried.bursts.length, 0);
    assert.deepEqual(retried.cues, []);
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


test('every round outcome has its own cue without replaying duplicate actions', async () => {
  const mapping = { win: 'hit', lose: 'miss', tie: 'tie', blocked: 'block', dodge: 'power' };
  for (const [outcome, cue] of Object.entries(mapping)) {
    const initial = { ...active, enemy_hp: 3 };
    const reply = { ...initial, round: 1, action_revision: 1, outcome };
    const fresh = fixture({ initial, reply });
    assert.equal(fresh.music.at(-1), true);
    await fresh.moves[0].click();
    assert.deepEqual(fresh.cues, [cue]);
    const repeat = fixture({ initial, reply, duplicate: true });
    await repeat.moves[0].click();
    assert.deepEqual(repeat.cues, []);
  }
});
