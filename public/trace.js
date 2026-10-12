// Geometry is in the same 0–100 coordinates as config/alphabet.json.
// A score rewards following the whole print shape, not a particular stroke order.
const TOLERANCE = 10;
const SAMPLE_STEP = 1.5;
const MAX_POINTS = 12000;
const MAX_SAMPLES = 1600;

const clamp = (value, low = 0, high = 1) => Math.min(high, Math.max(low, value));
const distance = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1]);
const validPoint = (point) => Array.isArray(point) && point.length >= 2 &&
  Number.isFinite(point[0]) && Number.isFinite(point[1]) &&
  Math.abs(point[0]) <= 1000 && Math.abs(point[1]) <= 1000;

function geometry(paths) {
  const strokes = [];
  const dots = [];
  let points = 0;
  if (!Array.isArray(paths)) return { strokes, dots, segments: [], length: 0, points };

  for (const path of paths) {
    if (!Array.isArray(path)) continue;
    const segments = [];
    let previous = null;
    let isolated = null;
    for (const point of path) {
      if (++points > MAX_POINTS) break;
      if (!validPoint(point)) {
        previous = null;
        continue;
      }
      isolated = point;
      if (previous) {
        const length = distance(previous, point);
        if (length > 0.001) segments.push({ a: previous, b: point, length });
      }
      previous = point;
    }
    if (segments.length) {
      strokes.push({ segments, length: segments.reduce((sum, segment) => sum + segment.length, 0) });
    } else if (isolated) {
      dots.push(isolated);
    }
    if (points > MAX_POINTS) break;
  }

  const segments = strokes.flatMap((stroke) => stroke.segments);
  return {
    strokes, dots, segments,
    length: segments.reduce((sum, segment) => sum + segment.length, 0),
    points: Math.min(points, MAX_POINTS)
  };
}

function pointSegmentDistance(point, segment) {
  const dx = segment.b[0] - segment.a[0];
  const dy = segment.b[1] - segment.a[1];
  const projection = clamp(((point[0] - segment.a[0]) * dx +
    (point[1] - segment.a[1]) * dy) / (dx * dx + dy * dy));
  return Math.hypot(point[0] - segment.a[0] - projection * dx,
    point[1] - segment.a[1] - projection * dy);
}

function nearestDistance(point, segments, dots = []) {
  let nearest = Infinity;
  for (const segment of segments) {
    nearest = Math.min(nearest, pointSegmentDistance(point, segment));
    if (nearest < 0.01) return nearest;
  }
  for (const dot of dots) nearest = Math.min(nearest, distance(point, dot));
  return nearest;
}

// Samples are weighted by the length they represent. A stream of repeated
// pointer events or many tiny segments cannot outweigh a long wrong stroke.
function weightedMatch(segments, targets, dots = []) {
  const length = segments.reduce((sum, segment) => sum + segment.length, 0);
  const step = Math.max(SAMPLE_STEP, length / MAX_SAMPLES);
  let matched = 0;
  for (const segment of segments) {
    const count = Math.max(1, Math.ceil(segment.length / step));
    for (let index = 0; index < count; index++) {
      const t = (index + 0.5) / count;
      const point = [segment.a[0] + (segment.b[0] - segment.a[0]) * t,
        segment.a[1] + (segment.b[1] - segment.a[1]) * t];
      const gap = nearestDistance(point, targets, dots);
      const quality = clamp(1 - (gap / TOLERANCE) ** 2);
      matched += quality * segment.length / count;
    }
  }
  return length > 0 ? matched / length : 0;
}

export function scoreTrace(guidePaths, drawnPaths) {
  const guide = geometry(guidePaths);
  const drawn = geometry(drawnPaths);
  const result = {
    score: 0, coverage: 0, precision: 0,
    points: drawn.points, drawnLength: drawn.length, guideLength: guide.length
  };
  if (guide.length === 0 || drawn.length < 8 || drawn.segments.length === 0) return result;

  const strokeCoverage = guide.strokes.map((stroke) => weightedMatch(
    stroke.segments, drawn.segments,
    // A tap may make the dot of ј. Taps cannot fill an ordinary letter stroke.
    stroke.length <= 3 ? drawn.dots : []
  ));
  const coverage = guide.strokes.reduce((sum, stroke, index) =>
    sum + stroke.length * strokeCoverage[index], 0) / guide.length;
  const precision = weightedMatch(drawn.segments, guide.segments);
  const weakestStroke = Math.min(...strokeCoverage);
  const completeness = 0.65 + 0.35 * weakestStroke;
  // A little retracing is fine. Filling the board or repeatedly going over
  // one stroke does not earn credit for strokes that are still missing.
  const extraLength = Math.min(1, guide.length * 1.3 / drawn.length);
  let score = 100 * Math.sqrt(coverage * precision) * completeness * extraLength;
  if (weakestStroke < 0.45) score = Math.min(score, 64);

  return {
    ...result,
    score: Math.round(clamp(score, 0, 100)),
    coverage: Math.round(clamp(coverage) * 1000) / 1000,
    precision: Math.round(clamp(precision) * 1000) / 1000
  };
}

export function guidePathData(strokes) {
  if (!Array.isArray(strokes)) return [];
  return strokes.filter((stroke) => Array.isArray(stroke) && stroke.length > 0 &&
    stroke.every(validPoint)).map((stroke) =>
    stroke.map((point, index) => `${index === 0 ? "M" : "L"}${point[0]} ${point[1]}`).join(" ")
  );
}

// Position direction hints along the actual polyline, including curved strokes.
// Short marks (the dot of ј) need a starting point, not a misleading arrow.
export function guideAnnotations(strokes) {
  const badges = [];
  return strokes.map((path) => {
    const start = path[0];
    const offsets = [[0, 0], [-9, 0], [9, 0], [0, -9], [0, 9], [-9, -9], [9, -9]];
    const badge = offsets.map(([x, y]) => [clamp(start[0] + x, 5, 95), clamp(start[1] + y, 5, 95)])
      .find((point) => badges.every((other) => distance(point, other) >= 8)) || start;
    badges.push(badge);
    const segments = path.slice(1).map((point, index) => ({ a: path[index], b: point, length: distance(path[index], point) }))
      .filter((segment) => segment.length > 0);
    const length = segments.reduce((sum, segment) => sum + segment.length, 0);
    if (length < 8) return { start, badge, arrow: null };
    function at(position) {
      for (const segment of segments) {
        if (position <= segment.length) {
          const t = position / segment.length;
          return [segment.a[0] + (segment.b[0] - segment.a[0]) * t,
            segment.a[1] + (segment.b[1] - segment.a[1]) * t];
        }
        position -= segment.length;
      }
      return path.at(-1);
    }
    const end = Math.min(16, length * .65), tip = at(end);
    const before = at(end - 1), after = at(end + 1);
    const tangent = distance(before, after);
    if (!tangent) return { start, badge, arrow: null };
    const dx = (after[0] - before[0]) / tangent, dy = (after[1] - before[1]) / tangent;
    const arrow = [[tip[0] - dx * 3 - dy * 2, tip[1] - dy * 3 + dx * 2], tip,
      [tip[0] - dx * 3 + dy * 2, tip[1] - dy * 3 - dx * 2]];
    return { start, badge, arrow };
  });
}
