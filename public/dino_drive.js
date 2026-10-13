import { burst } from './fx.js';
import { createGameAudio } from './game_audio.js';
import { appendDriveMove, driveFrameDelta, evaluateDrive } from './dino_drive_engine.js';

(() => {
  const root = document.querySelector('[data-dino-drive]');
  if (!root) return;
  const gameAudio = createGameAudio('drive');
  const $ = selector => root.querySelector(selector);
  const board = $('[data-drive-board]');
  const car = $('[data-drive-car]');
  const overlay = $('[data-drive-overlay]');
  const left = $('[data-drive-left]'), right = $('[data-drive-right]');
  const csrf = document.querySelector('meta[name="csrf-token"]')?.content;
  let course = {}, moves = [], elapsed = 0, previous = null, frame = null;
  let running = false, pending = false, hits = 0, savedAt = 0, pointer = null;
  let finishUrl = root.dataset.finishUrl;
  let nextUrl = root.dataset.nextUrl;
  let rocks = [];
  try { course = JSON.parse($('[data-drive-state]').textContent) || {}; } catch { /* Intro remains usable. */ }

  const cacheKey = () => course.token ? `cirilo-drive-${course.token}` : null;
  function save() {
    try { if (cacheKey()) sessionStorage.setItem(cacheKey(), JSON.stringify({ elapsed_ms: Math.floor(elapsed), moves })); } catch { /* Private mode may refuse storage. */ }
  }
  function clearSave() {
    try { if (cacheKey()) sessionStorage.removeItem(cacheKey()); } catch { /* Nothing to clear. */ }
  }
  function restore() {
    try {
      const saved = JSON.parse(sessionStorage.getItem(cacheKey()));
      if (!saved || !Array.isArray(saved.moves) || saved.moves.length > 201 ||
          !Number.isInteger(saved.elapsed_ms) || saved.elapsed_ms < 0 || saved.elapsed_ms > course.duration_ms) return;
      const restored = [];
      for (const move of saved.moves) {
        if (!Number.isInteger(move.at_ms) || move.at_ms > saved.elapsed_ms ||
            !appendDriveMove(course, restored, move.at_ms, move.lane)) return;
      }
      moves = restored; elapsed = saved.elapsed_ms;
    } catch { /* A missing or old cache starts this same course from the beginning. */ }
  }
  async function post(url, body) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 12000);
    let response;
    try {
      response = await fetch(url, {
        method: 'POST', credentials: 'same-origin', signal: controller.signal,
        headers: { 'Accept': 'application/json', 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
        body: JSON.stringify(body)
      });
    } catch { throw new Error('Веза је прекинута. Покушај поново.'); }
    finally { clearTimeout(timeout); }
    let result;
    try { result = await response.json(); } catch { throw new Error('Веза је прекинута. Покушај поново.'); }
    if (!response.ok || result.success === false) throw new Error(result.error || 'Није сачувано. Покушај поново.');
    return result;
  }
  function error(message = '') {
    $('[data-drive-error]').hidden = !message;
    $('[data-drive-error]').textContent = message;
  }
  function announce(message) { $('[data-drive-live]').textContent = message; }
  function renderResources(hitCount, duration = elapsed) {
    const hearts = $('[data-drive-hearts]');
    const remaining = Math.max(0, (course.max_hits || 3) - hitCount);
    [...hearts.children].forEach((heart, index) => heart.classList.toggle('is-empty', index >= remaining));
    hearts.setAttribute('aria-label', `${remaining} срца`);
    const percent = Math.min(100, Math.floor(duration / (course.duration_ms || 24000) * 100));
    const progress = $('[data-drive-progress]');
    progress.style.setProperty('--drive-progress', `${percent}%`);
    progress.setAttribute('aria-valuenow', String(percent));
  }
  function showOverlay(title, detail, action, icon = 'shield') {
    gameAudio.setPlaying(false);
    overlay.hidden = false;
    $('[data-drive-title]').textContent = title;
    $('[data-drive-detail]').textContent = detail;
    for (const name of ['start', 'resume', 'retry', 'next']) $('[data-drive-' + name + ']').hidden = name !== action;
    $('[data-drive-demo]').hidden = action !== 'start';
    const medal = $('[data-drive-result-icon]');
    medal.classList.toggle('is-flag', icon === 'flag');
    medal.classList.toggle('is-rest', icon === 'rest');
    root.classList.toggle('is-driving', false);
    $('[data-drive-mrgud]').classList.remove('is-throwing');
    $('[data-drive-pause]').hidden = true;
    left.disabled = true; right.disabled = true;
  }
  function makeRocks() {
    const host = $('[data-drive-rocks]');
    host.replaceChildren();
    rocks = course.obstacles.map(obstacle => {
      const node = document.createElement('span');
      node.className = 'drive-rock';
      node.style.left = `${(obstacle.lane + .5) * 100 / 3}%`;
      node.innerHTML = '<svg viewBox="0 0 64 58" fill="none"><ellipse cx="33" cy="51" rx="26" ry="6" fill="#162937" fill-opacity=".24"/><path d="M6 36L15 13L36 5L53 18L59 43L42 53L17 50Z" fill="#b2aac1" stroke="#524768" stroke-width="3" stroke-linejoin="round"/><path d="M15 13L30 21L36 5M30 21L47 25L53 18M30 21L24 42L6 36M24 42L42 53L47 25" stroke="#7c718f" stroke-width="3" stroke-linejoin="round"/><path d="M18 17L12 33" stroke="#e3dfe8" stroke-width="4" stroke-linecap="round"/></svg>';
      host.append(node);
      return { node, obstacle };
    });
  }
  function render() {
    const state = evaluateDrive(course, moves, elapsed);
    car.style.left = `${(state.lane + .5) * 100 / 3}%`;
    renderResources(state.hits);
    left.disabled = !running || state.lane === 0;
    right.disabled = !running || state.lane === 2;
    let throwing = false;
    for (const { node, obstacle } of rocks) {
      const remaining = obstacle.at_ms - elapsed;
      const visible = remaining <= 2100 && remaining >= -220;
      node.hidden = !visible;
      if (!visible) continue;
      const progress = (2100 - remaining) / 2100;
      node.style.top = `${12 + progress * 65}%`;
      node.style.setProperty('--rock-scale', String(.5 + progress * .5));
      node.classList.toggle('is-danger', remaining < 750 && remaining > 0);
      node.classList.toggle('is-passed', remaining < 0);
      if (remaining > 1500) throwing = true;
    }
    $('[data-drive-mrgud]').classList.toggle('is-throwing', throwing && running);
    return state;
  }
  function move(direction) {
    if (!running || pending) return;
    const lane = evaluateDrive(course, moves, elapsed).lane;
    if (appendDriveMove(course, moves, elapsed, lane + direction)) {
      gameAudio.play('turn');
      render(); save();
    }
  }
  function pause() {
    if (!running) return;
    running = false; previous = null;
    cancelAnimationFrame(frame); save();
    showOverlay('Пауза', 'Ауто те чека.', 'resume');
    announce('Вожња је паузирана.');
  }
  function resume() {
    if (pending || document.hidden) return;
    error();
    const state = evaluateDrive(course, moves, elapsed);
    if (state.status !== 'active') { finish(); return; }
    overlay.hidden = true; running = true; previous = null;
    gameAudio.setPlaying(true);
    root.classList.add('is-driving');
    $('[data-drive-pause]').hidden = false;
    board.focus({ preventScroll: true });
    announce('Вози! Стрелицама или додиром обилази камење.');
    frame = requestAnimationFrame(tick);
  }
  function tick(now) {
    if (!running) return;
    elapsed = Math.min(course.duration_ms, elapsed + driveFrameDelta(now, previous, document.hidden));
    previous = now;
    const state = render();
    if (state.hits > hits) {
      hits = state.hits;
      car.classList.remove('is-hit'); void car.offsetWidth; car.classList.add('is-hit');
      gameAudio.play('crash');
      burst({ kind: 'hit', origin: car, label: 'УПС!', sound: false });
      $('[data-drive-taunt]').textContent = 'Хоп!';
      announce(`Камен! Остало је ${Math.max(0, course.max_hits - hits)} срца.`);
    }
    if (elapsed - savedAt >= 1000) { savedAt = elapsed; save(); }
    if (state.status !== 'active') { elapsed = state.elapsed_ms; finish(); return; }
    frame = requestAnimationFrame(tick);
  }
  function finished(result, celebrate = true) {
    running = false; pending = false; previous = null;
    cancelAnimationFrame(frame);
    const won = result.status === 'won';
    course.status = result.status;
    elapsed = result.elapsed_ms ?? elapsed;
    hits = result.hits ?? hits;
    renderResources(hits, won ? course.duration_ms : elapsed);
    if (result.next_url) nextUrl = result.next_url;
    $('[data-drive-next]').href = nextUrl;
    root.classList.toggle('is-won', won);
    root.classList.toggle('is-lost', !won);
    root.querySelector('.drive-controls').hidden = true;
    $('[data-drive-skip]').hidden = true;
    showOverlay(won ? 'Штит је твој!' : 'Ништа страшно!',
      won ? 'Чува те од једног ударца у арени.' : 'Дино је добро. Настављамо мисију!', 'next', won ? 'shield' : 'rest');
    $('[data-drive-taunt]').textContent = won ? 'Опа!' : 'Хе-хе!';
    announce(won ? 'Стигао си! Освојен је један штит за арену.' : 'Крај вожње. Настави мисију.');
    clearSave();
    if (celebrate) {
      gameAudio.play(won ? 'win' : 'lose');
      burst({ kind: won ? 'victory' : 'hit', origin: $('[data-drive-result-icon]'), label: won ? '+1 ШТИТ!' : 'ИДЕМО ДАЉЕ!', sound: false });
    }
    $('[data-drive-next]').focus({ preventScroll: true });
  }
  async function finish() {
    if (pending) return;
    running = false; pending = true; previous = null;
    cancelAnimationFrame(frame); save();
    showOverlay('Још тренутак…', 'Чувамо твоју вожњу.', null);
    error();
    try {
      const result = await post(finishUrl, { token: course.token, moves, elapsed_ms: Math.floor(elapsed) });
      finished(result);
    } catch (reason) {
      pending = false;
      showOverlay('Вожња је сачувана овде.', 'Покушај поново када се веза врати.', 'retry');
      error(reason.message);
    }
  }
  async function start() {
    if (pending) return;
    pending = true; $('[data-drive-start]').disabled = true; error();
    try {
      const result = await post(root.dataset.startUrl, {});
      course = result.state || result;
      finishUrl = result.finish_url || root.dataset.finishUrl;
      nextUrl = result.next_url || root.dataset.nextUrl;
      if (course.status !== 'active') { finished(course, false); return; }
      if (!course.token || !Array.isArray(course.obstacles) || !course.duration_ms) throw new Error('Вожња није спремна. Покушај поново.');
      moves = []; elapsed = 0; hits = 0;
      restore(); makeRocks(); pending = false;
      resume();
    } catch (reason) { pending = false; error(reason.message); }
    finally { $('[data-drive-start]').disabled = false; }
  }

  $('[data-drive-start]').addEventListener('click', start);
  $('[data-drive-resume]').addEventListener('click', resume);
  $('[data-drive-retry]').addEventListener('click', finish);
  $('[data-drive-pause]').addEventListener('click', pause);
  left.addEventListener('click', () => move(-1));
  right.addEventListener('click', () => move(1));
  document.addEventListener('keydown', event => {
    if (!running || event.ctrlKey || event.metaKey || event.altKey) return;
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      event.preventDefault(); move(event.key === 'ArrowLeft' ? -1 : 1);
    } else if (event.key === 'Escape' || event.key === 'p' || event.key === 'P') { event.preventDefault(); pause(); }
  });
  board.addEventListener('pointerdown', event => {
    if (!running || event.target.closest('button, a')) return;
    pointer = { x: event.clientX, y: event.clientY, id: event.pointerId };
    board.setPointerCapture?.(event.pointerId);
  });
  board.addEventListener('pointerup', event => {
    if (!running || !pointer || pointer.id !== event.pointerId) return;
    const dx = event.clientX - pointer.x, dy = event.clientY - pointer.y;
    pointer = null;
    if (Math.abs(dx) > 24 && Math.abs(dx) > Math.abs(dy)) move(dx > 0 ? 1 : -1);
    else if (Math.abs(dy) < 24) {
      const bounds = board.getBoundingClientRect();
      const target = Math.min(2, Math.max(0, Math.floor((event.clientX - bounds.left) / bounds.width * 3)));
      const lane = evaluateDrive(course, moves, elapsed).lane;
      if (target !== lane) move(Math.sign(target - lane));
    }
  });
  board.addEventListener('pointercancel', () => { pointer = null; });
  document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); });
  window.addEventListener('pagehide', () => { pause(); cancelAnimationFrame(frame); if (course.status === 'active') save(); });
  $('[data-drive-skip]')?.addEventListener('submit', () => { gameAudio.setPlaying(false); running = false; cancelAnimationFrame(frame); clearSave(); });

  if (course.status === 'active' && Array.isArray(course.obstacles)) {
    restore(); makeRocks(); hits = evaluateDrive(course, moves, elapsed).hits; render();
    showOverlay('Настављамо?', 'Обилази камење.', 'resume');
  } else if (['won', 'lost', 'skipped'].includes(course.status)) finished(course, false);
})();
