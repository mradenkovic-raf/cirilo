import { scoreTrace, guidePathData, guideAnnotations } from './trace.js';

// One normalized pad is shared by single-letter and whole-word exercises.
export function createTracePad(board, isLocked, onChange = () => {}) {
  const canvas = board.querySelector('canvas'), guide = board.querySelector('svg');
  const context = canvas.getContext('2d'), ns = 'http://www.w3.org/2000/svg';
  let guides = [], paths = [], current = null, pointer = null;

  function redraw() {
    const size = board.clientWidth;
    if (!size) return;
    const pixels = Math.round(size * (window.devicePixelRatio || 1));
    canvas.width = pixels; canvas.height = pixels;
    context.setTransform(pixels / 100, 0, 0, pixels / 100, 0, 0);
    context.lineWidth = 4.4; context.strokeStyle = '#79a83f'; context.fillStyle = '#79a83f';
    context.lineCap = 'round'; context.lineJoin = 'round';
    paths.forEach(path => {
      context.beginPath();
      if (path.length === 1) { context.arc(...path[0], 2.2, 0, Math.PI * 2); context.fill(); }
      else { path.forEach((point, index) => index ? context.lineTo(...point) : context.moveTo(...point)); context.stroke(); }
    });
  }
  function setGuide(next) {
    guides = next; guide.replaceChildren();
    guidePathData(guides).forEach(data => {
      const path = document.createElementNS(ns, 'path'); path.setAttribute('d', data); guide.append(path);
    });
    guideAnnotations(guides).forEach(({ start, badge, arrow }, index) => {
      if (arrow) {
        const direction = document.createElementNS(ns, 'path');
        direction.setAttribute('d', guidePathData([arrow])[0]);
        direction.classList.add('stroke-direction'); guide.append(direction);
      }
      if (start[0] !== badge[0] || start[1] !== badge[1]) {
        const leader = document.createElementNS(ns, 'path');
        leader.setAttribute('d', guidePathData([[badge, start]])[0]);
        leader.classList.add('stroke-leader'); guide.append(leader);
      }
      const dot = document.createElementNS(ns, 'circle');
      dot.setAttribute('cx', badge[0]); dot.setAttribute('cy', badge[1]);
      dot.setAttribute('r', '3.5'); dot.classList.add('start-point'); guide.append(dot);
      const label = document.createElementNS(ns, 'text');
      label.setAttribute('x', badge[0]); label.setAttribute('y', badge[1] + 1.4);
      label.setAttribute('text-anchor', 'middle'); label.classList.add('start-number'); label.textContent = index + 1;
      guide.append(label);
    });
  }
  function point(event) {
    const rect = canvas.getBoundingClientRect();
    return [Math.max(0, Math.min(100, (event.clientX - rect.left) * 100 / rect.width)),
      Math.max(0, Math.min(100, (event.clientY - rect.top) * 100 / rect.height))];
  }
  canvas.addEventListener('pointerdown', event => {
    if (isLocked() || pointer !== null || !guides.length || paths.length >= 300 || (event.pointerType === 'mouse' && event.button !== 0)) return;
    event.preventDefault(); pointer = event.pointerId; canvas.setPointerCapture(pointer);
    current = [point(event)]; paths.push(current); onChange(); redraw();
  });
  canvas.addEventListener('pointermove', event => {
    if (event.pointerId !== pointer || !current || isLocked()) return;
    event.preventDefault();
    const coalesced = event.getCoalescedEvents?.();
    for (const item of (coalesced?.length ? coalesced : [event])) {
      const next = point(item), last = current.at(-1);
      if (Math.hypot(next[0] - last[0], next[1] - last[1]) > .35 && current.length < 4000) current.push(next);
    }
    redraw();
  });
  function finish(event) {
    if (event.pointerId !== pointer || !current) return;
    if (event.type === 'pointerup') current.push(point(event));
    pointer = null; current = null; redraw(); onChange();
  }
  ['pointerup', 'pointercancel', 'lostpointercapture'].forEach(name => canvas.addEventListener(name, finish));
  canvas.addEventListener('contextmenu', event => event.preventDefault());
  new ResizeObserver(redraw).observe(board);
  return {
    set(guidePaths, drawn = []) { pointer = null; current = null; paths = drawn; setGuide(guidePaths); redraw(); },
    clear() { pointer = null; current = null; paths = []; redraw(); onChange(); },
    paths: () => paths,
    hasInk: () => paths.length > 0,
    drawing: () => pointer !== null,
    hasStroke(minimum = 15) {
      let length = 0;
      for (const path of paths) {
        for (let index = 1; index < path.length; index++) {
          length += Math.hypot(path[index][0] - path[index - 1][0], path[index][1] - path[index - 1][1]);
          if (length >= minimum) return true;
        }
      }
      return false;
    },
    score: () => scoreTrace(guides, paths)
  };
}
