// The server's saved cursor is the source of truth, including extra practice
// inserted after a mistake. An incorrect answer never earns another dot.
export function setupMissionPath(header) {
  const path = header?.querySelector('[data-mission-path]');
  if (!path) return null;
  const dots = path.querySelector('[data-mission-dots]');
  const label = header.querySelector('[data-mission-label]');

  return {
    update({ cursor, total, correct }) {
      cursor = Number(cursor); total = Number(total);
      if (!Number.isInteger(cursor) || !Number.isInteger(total) || total < 1 || cursor < 0 || cursor > total) return;
      if (dots.children.length !== total) {
        const steps = Array.from({ length: total }, (_, index) => {
          const dot = path.ownerDocument.createElement('span');
          dot.className = 'mission-dot';
          dot.dataset.missionStep = String(index + 1);
          dot.style.left = `${(index + 1) / total * 100}%`;
          return dot;
        });
        dots.replaceChildren(...steps);
      }
      Array.from(dots.children).forEach((dot, index) => dot.classList.toggle('is-done', index < cursor));
      path.style.setProperty('--mission-position', `${cursor / total * 100}%`);
      path.setAttribute('aria-valuenow', cursor);
      path.setAttribute('aria-valuemax', total);
      path.setAttribute('aria-valuetext', `Завршено ${cursor} од ${total} задатака. Мргуд чека у арени.`);
      if (label) label.textContent = correct ? `Готово ${cursor} / ${total}` : `Задатак ${Math.min(cursor + 1, total)} / ${total}`;
    }
  };
}
