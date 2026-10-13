// The server evaluates the same timestamped lane changes before awarding a shield.
export const DRIVE_MOVE_DELAY = 120;

export function laneAtTime(course, moves, atMs) {
  let lane = course.starting_lane ?? 1;
  for (const move of moves) {
    if (move.at_ms > atMs) break;
    lane = move.lane;
  }
  return lane;
}

export function evaluateDrive(course, moves, elapsedMs) {
  const elapsed = Math.max(0, Math.min(course.duration_ms, Math.floor(elapsedMs)));
  const collisions = [];
  for (const obstacle of course.obstacles) {
    if (obstacle.at_ms > elapsed) break;
    if (laneAtTime(course, moves, obstacle.at_ms) === obstacle.lane) {
      collisions.push(obstacle.at_ms);
      if (collisions.length === course.max_hits) break;
    }
  }
  const lost = collisions.length >= course.max_hits;
  return {
    status: lost ? 'lost' : elapsed >= course.duration_ms ? 'won' : 'active',
    hits: collisions.length,
    elapsed_ms: lost ? collisions.at(-1) : elapsed,
    lane: laneAtTime(course, moves, elapsed),
    collisions
  };
}

export function appendDriveMove(course, moves, elapsedMs, requestedLane) {
  const at = Math.floor(elapsedMs);
  const last = moves.at(-1);
  const lane = last?.lane ?? course.starting_lane ?? 1;
  if (!Number.isFinite(at) || !Number.isInteger(requestedLane) || requestedLane < 0 || requestedLane > 2 ||
      Math.abs(requestedLane - lane) !== 1 || at < 0 || at > course.duration_ms ||
      (last && at - last.at_ms < DRIVE_MOVE_DELAY)) return false;
  moves.push({ at_ms: at, lane: requestedLane });
  return true;
}

// Time spent away from the page cannot jump the car into several rocks at once.
export function driveFrameDelta(now, previous, paused = false) {
  if (paused || previous === null || previous === undefined) return 0;
  return Math.max(0, Math.min(50, now - previous));
}
