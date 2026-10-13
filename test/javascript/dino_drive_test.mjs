import test from 'node:test';
import assert from 'node:assert/strict';
import { appendDriveMove, driveFrameDelta, evaluateDrive, laneAtTime } from '../../public/dino_drive_engine.js';

const course = {
  duration_ms: 24000, starting_lane: 1, max_hits: 3,
  obstacles: [{ at_ms: 3500, lane: 1 }, { at_ms: 5000, lane: 0 },
    { at_ms: 6500, lane: 2 }, { at_ms: 8000, lane: 1 }, { at_ms: 9500, lane: 1 }]
};

test('race awards a win only after the entire course, with zero, one or two collisions', () => {
  const moves = [{ at_ms: 3000, lane: 0 }, { at_ms: 4500, lane: 1 }, { at_ms: 7500, lane: 0 }];
  assert.equal(evaluateDrive(course, moves, 23999).status, 'active');
  assert.deepEqual(evaluateDrive(course, moves, 24000), {
    status: 'won', hits: 0, elapsed_ms: 24000, lane: 0, collisions: []
  });
  for (const rocks of [[{ at_ms: 3500, lane: 1 }], [{ at_ms: 3500, lane: 1 }, { at_ms: 5000, lane: 1 }]]) {
    const state = evaluateDrive({ ...course, obstacles: rocks }, [], 24000);
    assert.equal(state.status, 'won');
    assert.equal(state.hits, rocks.length);
  }
});

test('third collision ends the race at its actual time, before any later rocks', () => {
  const state = evaluateDrive(course, [], 24000);
  assert.equal(state.status, 'lost');
  assert.equal(state.hits, 3);
  assert.equal(state.elapsed_ms, 9500);
  assert.deepEqual(state.collisions, [3500, 8000, 9500]);
  assert.equal(evaluateDrive(course, [], 9499).status, 'active');
});

test('a timestamped lane change affects its exact collision, never a preceding rock', () => {
  const moves = [{ at_ms: 3500, lane: 0 }, { at_ms: 5001, lane: 1 }];
  assert.equal(laneAtTime(course, moves, 3499), 1);
  assert.equal(laneAtTime(course, moves, 3500), 0);
  assert.deepEqual(evaluateDrive(course, moves, 5000).collisions, [5000]);
  assert.deepEqual(evaluateDrive(course, moves, 5001).collisions, [5000]);
});

test('lane controls accept only adjacent changes and enforce the server cooldown', () => {
  const moves = [];
  assert.equal(appendDriveMove(course, moves, 0, 0), true);
  assert.equal(appendDriveMove(course, moves, 119, 1), false);
  assert.equal(appendDriveMove(course, moves, 120, 1), true);
  assert.equal(appendDriveMove(course, moves, 240, 2), true);
  for (const [at, lane] of [[360, 0], [360, 3], [360, 2], [360, 1.5], [200, 1], [-1, 1], [24001, 1], [NaN, 1]]) {
    assert.equal(appendDriveMove(course, moves, at, lane), false);
  }
  assert.deepEqual(moves, [{ at_ms: 0, lane: 0 }, { at_ms: 120, lane: 1 }, { at_ms: 240, lane: 2 }]);
});

test('background pause and a slow frame never skip a large section of the road', () => {
  assert.equal(driveFrameDelta(15000, null), 0);
  assert.equal(driveFrameDelta(100016, 100000), 16);
  assert.equal(driveFrameDelta(100000, 1000), 50);
  assert.equal(driveFrameDelta(100000, 1000, true), 0);
  assert.equal(driveFrameDelta(1, 1000), 0);
  assert.equal(evaluateDrive(course, [], -100).elapsed_ms, 0);
});

test('every single-lane rock leaves a reachable safe lane during a course', () => {
  const manyRocks = Array.from({ length: 14 }, (_, index) => ({ at_ms: 3000 + index * 1500, lane: index % 3 }));
  const race = { ...course, obstacles: manyRocks };
  const moves = [];
  for (const rock of manyRocks) {
    const lane = laneAtTime(race, moves, rock.at_ms);
    if (lane === rock.lane) assert.equal(appendDriveMove(race, moves, rock.at_ms - 700, lane === 2 ? 1 : lane + 1), true);
  }
  assert.equal(evaluateDrive(race, moves, 24000).hits, 0);
  assert.equal(evaluateDrive(race, moves, 24000).status, 'won');
});
