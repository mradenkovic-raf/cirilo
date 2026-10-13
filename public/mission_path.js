// The server's saved cursor is the source of truth, including extra practice
// inserted after a mistake. An incorrect answer never earns another dot.
export function setupMissionPath(header) {
  const path = header?.querySelector('[data-mission-path]');
  if (!path) return null;
  const dots = path.querySelector('[data-mission-dots]');
  const label = header.querySelector('[data-mission-label]');
  const drive = path.querySelector('[data-mission-drive]');

  return {
    update({ cursor, total, correct, drive_checkpoint }) {
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
      if (drive && drive_checkpoint && Number.isInteger(drive_checkpoint.step) && drive_checkpoint.step > 0 && drive_checkpoint.step <= total &&
          ['upcoming', 'current', 'won', 'lost', 'skipped', 'passed'].includes(drive_checkpoint.status) && typeof drive_checkpoint.label === 'string') {
        drive.dataset.step = String(drive_checkpoint.step);
        drive.dataset.status = drive_checkpoint.status;
        drive.dataset.label = drive_checkpoint.label;
        drive.setAttribute('title', drive_checkpoint.label);
      }
      if (drive) drive.style.left = `${Number(drive.dataset.step) / total * 100}%`;
      const driveLabel = drive?.dataset.label ? ` ${drive.dataset.label}` : '';
      path.setAttribute('aria-valuetext', `Завршено ${cursor} од ${total} задатака.${driveLabel} Мргуд чека у арени.`);
      if (label) label.textContent = correct ? `Готово ${cursor} / ${total}` : `Задатак ${Math.min(cursor + 1, total)} / ${total}`;
    }
  };
}
