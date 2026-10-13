import { createTracePad } from './trace_pad.js';
import { setupWordWriting } from './writing.js';
import { setupVariety } from './variety.js';
import { setupMissionPath } from './mission_path.js';
import { burst } from './fx.js';

// The extra navigation also works without JavaScript, using native details.
const moreMenu = document.querySelector('.more-menu');
document.addEventListener('click', event => {
  if (moreMenu?.open && !moreMenu.contains(event.target)) moreMenu.open = false;
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && moreMenu?.open) {
    moreMenu.open = false;
    moreMenu.querySelector('summary').focus();
  }
});

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
let muted = false;
try { muted = localStorage.getItem('cirilo-muted') === 'true'; } catch { /* Storage may be disabled. */ }
const soundToggle = $('.sound-toggle');
function updateSound() {
  soundToggle?.setAttribute('aria-pressed', String(muted));
  soundToggle?.setAttribute('aria-label', muted ? 'Укључи звук и музику' : 'Искључи звук и музику');
}
updateSound();
soundToggle?.addEventListener('click', () => {
  muted = !muted;
  try { localStorage.setItem('cirilo-muted', String(muted)); } catch { /* Keep the setting for this page. */ }
  if (muted) window.speechSynthesis?.cancel();
  updateSound();
});
window.addEventListener('storage', event => {
  if (event.key !== 'cirilo-muted' && event.key !== null) return;
  muted = event.key === 'cirilo-muted' && event.newValue === 'true';
  if (muted) window.speechSynthesis?.cancel();
  updateSound();
});
window.addEventListener('pageshow', event => {
  if (!event.persisted) return;
  try { muted = localStorage.getItem('cirilo-muted') === 'true'; } catch { /* Keep the in-page preference. */ }
  if (muted) window.speechSynthesis?.cancel();
  updateSound();
});
let toastTimer;
function toast(message) {
  const box = $('.toast');
  box.textContent = message;
  box.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { box.hidden = true; }, 6000);
}

function rewardFeedback(root, completed) {
  root.classList.remove('power-success');
  requestAnimationFrame(() => root.classList.add('power-success'));
  const dino = $('.feedback-dino', root);
  if (dino) dino.dataset.mood = completed ? 'super' : 'happy';
  burst({ kind: completed ? 'mission' : 'answer', origin: dino });
}

// The explicit listen button uses only an installed Serbian voice. No wrong-
// language fallback silently pronounces Cyrillic as English letter names.
function speak(text) {
  if (!('speechSynthesis' in window)) {
    toast('Овај прегледач нема изговор. Задатак можеш да прочиташ на екрану.'); return;
  }
  const voices = window.speechSynthesis.getVoices();
  const voice = voices.find(item => /^sr(?:[-_]|$)/i.test(item.lang));
  if (!voice) {
    toast('На уређају нема српског гласа. За сада прочитајте задатак заједно.'); return;
  }
  window.speechSynthesis.cancel();
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.voice = voice; utterance.lang = voice.lang; utterance.rate = 0.82; utterance.pitch = 1.06;
  utterance.onerror = event => {
    if (!['interrupted', 'canceled'].includes(event.error)) toast('Изговор тренутно није доступан. Покушај поново.');
  };
  window.speechSynthesis.speak(utterance);
}
if ('speechSynthesis' in window) window.speechSynthesis.getVoices();
$$('[data-speak]').forEach(button => button.addEventListener('click', () => speak(button.dataset.speak)));

if ($('[data-celebrate]')) burst({ kind: 'unlock', origin: $('.reward-art'), sound: false });

const exercise = $('[data-exercise]');
if (exercise) setupExercise(exercise);

async function requestJSON(url, payload) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 18000);
  try {
    const response = await fetch(url, {
      method: 'POST', credentials: 'same-origin', signal: controller.signal,
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': $('meta[name="csrf-token"]').content },
      body: JSON.stringify(payload)
    });
    let data;
    try { data = await response.json(); } catch { throw new Error('Нисмо сачували одговор. Покушај поново.'); }
    return { response, data };
  } catch (error) {
    if (error.name === 'AbortError') throw new Error('Веза је успорила. Твој рад је још ту — покушај поново.');
    throw error;
  } finally { clearTimeout(timer); }
}

function setupExercise(root) {
  let pending = false, finished = false;
  const missionPath = setupMissionPath($('[data-mission-header]'));
  const bottom = $('.exercise-bottom', root);
  const mentor = $('.mentor-message', root);
  const panel = $('.feedback-panel', root);
  const title = $('[data-feedback-title]', root);
  const detail = $('[data-feedback-detail]', root);
  const next = $('[data-next]', root);
  const choices = $$('[data-answer]', root);
  const steps = $$('[data-task-step]', root);
  const requestStatus = $('[data-request-status]', root);
  function setStage(stage) {
    const current = steps.findIndex(step => step.dataset.taskStep === stage);
    root.dataset.stage = stage;
    steps.forEach((step, index) => {
      step.classList.toggle('is-current', index === current);
      step.classList.toggle('is-done', index < current);
      if (index === current) step.setAttribute('aria-current', 'step'); else step.removeAttribute('aria-current');
    });
  }
  setStage($('[data-memory-study]', root) ? 'study' : 'work');
  const trace = root.dataset.kind === 'trace' ? setupTrace(root, () => finished || pending, setStage) : null;
  const composer = $('[data-composer]', root) ? setupComposer(root, () => finished || pending, setStage) : null;

  const writing = $('[data-word-writing]', root) ? setupWordWriting(root, () => finished || pending, setStage) : null;
  const variety = setupVariety(root, () => finished || pending, setStage);

  function showNext(url, label = 'Даље') {
    next.href = url; next.hidden = false;
    $('[data-next-label]', next).textContent = label;
    setStage('next');
    root.classList.add('has-next');
    composer?.lock(); writing?.lock(); variety?.lock(); trace?.refresh();
  }

  function busy(value, message = 'Чувам одговор…') {
    root.setAttribute('aria-busy', String(value));
    requestStatus.hidden = !value;
    requestStatus.textContent = message;
    root.classList.toggle('is-pending', value);
    composer?.refresh(); writing?.refresh(); variety?.refresh(); trace?.refresh();
    // The feedback panel is hidden while pending, so focus only after it opens.
    if (!value && finished && !next.hidden) next.focus({ preventScroll: true });
  }

  function feedback(heading, message, success = false) {
    mentor.hidden = true; panel.hidden = false;
    title.textContent = heading; detail.textContent = message;
    bottom.classList.toggle('success', success); bottom.classList.toggle('try-again', !success);
    requestAnimationFrame(() => {
      const meaning = $('[data-meaning]', root);
      const showingMeaning = success && meaning && !meaning.hidden;
      (showingMeaning ? meaning : bottom).scrollIntoView({ block: showingMeaning ? 'start' : 'nearest', behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
    });
  }

  async function submit(payload, button) {
    if (pending || finished) return;
    pending = true;
    choices.forEach(item => { item.disabled = true; });
    if (button) button.disabled = true;
    busy(true);
    try {
      const { response, data } = await requestJSON(root.dataset.endpoint, {
        exercise_id: root.dataset.id, ...payload
      });
      if (!response.ok || !data.success) {
        if (response.status === 409 && data.next_url) {
          finished = true; feedback('Настави где си стао.', 'Овај изазов је већ завршен на другом екрану.');
          showNext(data.next_url); return;
        }
        throw new Error(data.error || 'Нисмо сачували одговор. Покушај поново.');
      }
      if (data.correct) {
        finished = true;
        button?.classList.add('correct');
        feedback(data.feedback, data.xp_earned ? `+${data.xp_earned} XP` : 'Настави мисију.', true);
        if (data.meaning) showMeaning(data.meaning);
        const balance = data.xp_balance ?? data.total_xp;
        const xp = $('.xp-pill strong'); if (xp) xp.textContent = balance;
        $('.xp-pill')?.setAttribute('aria-label', `Твој XP за куповину: ${balance}. Отвори продавницу.`);
        missionPath?.update(data);
        showNext(data.next_url, data.completed ? 'Моја награда' : 'Даље');
        if (!data.duplicate && Number(data.xp_earned) > 0) rewardFeedback(root, data.completed);
      } else {
        button?.classList.add('incorrect');
        if (data.recovery_required) {
          finished = true;
          feedback('Хајде кратко да поновимо.', 'Уради једну вежбу, па се враћамо на овај задатак.');
          writing?.review(data.letter_feedback, true);
          showNext(data.next_url, 'Идемо на вежбу');
        } else {
          feedback('Хајде још једном.', root.dataset.kind === 'trace' ? 'Обриши свој траг, па напиши цело слово.' : root.dataset.kind === 'story_action' ? 'Прочитај целу реченицу, па изабери слику.' : 'Погледај задатак још једном, па промени свој одговор.');
          writing?.review(data.letter_feedback);
        }
        missionPath?.update(data);
        if (trace) trace.showGuide();
        setTimeout(() => button?.classList.remove('incorrect'), 450);
      }
    } catch (error) {
      feedback('Одговор још није сачуван.', error.message || 'Провери везу и покушај поново.');
    } finally {
      pending = false;
      if (!finished) {
        choices.forEach(item => { item.disabled = false; });
        if (button) button.disabled = false;
      }
      busy(false);
    }
  }
  function showMeaning(meaning) {
    $('[data-task-body]', root).hidden = true;
    const card = $('[data-meaning]', root);
    $('[data-task-title]', root).textContent = 'Реч је оживела!';
    const picture = $('[data-meaning-picture]', card);
    picture.textContent = meaning.emoji; picture.setAttribute('aria-label', meaning.word);
    if (typeof meaning.image_url === 'string' && /^\/school_images\/[a-z_]+\.svg\?v=[a-f0-9]{12}$/.test(meaning.image_url)) {
      const illustration = document.createElement('img');
      illustration.src = meaning.image_url; illustration.alt = ''; illustration.className = 'word-illustration';
      picture.replaceChildren(illustration);
    }
    $('[data-meaning-word]', card).textContent = meaning.word;
    $('[data-meaning-sentence]', card).textContent = meaning.sentence;
    card.hidden = false;
  }
  $('[data-memory-ready]', root)?.addEventListener('click', async event => {
    if (pending || finished) return;
    const button = event.currentTarget;
    pending = true; button.disabled = true;
    busy(true, 'Спремам следећи корак…');
    try {
      const { response, data } = await requestJSON(root.dataset.memorizeEndpoint, { exercise_id: root.dataset.id });
      if (!response.ok || !data.success) {
        if (response.status === 409 && data.next_url) {
          finished = true; feedback('Настави мисију.', data.error);
          showNext(data.next_url); return;
        }
        throw new Error(data.error || 'Нисмо сачували почетак. Покушај поново.');
      }
      $('[data-memory-study]', root).remove();
      $('[data-composer]', root).hidden = false;
      $('[data-task-title]', root).textContent = 'Сложи реч по сећању.';
      $('.task-instruction', root).textContent = 'Додируј слова редом. Нека су вишак.';
      const speakButton = $('[data-speak]', root);
      if (speakButton) speakButton.dataset.speak = 'Сложи реч по сећању.';
      panel.hidden = true; mentor.hidden = false;
      bottom.classList.remove('try-again');
      setStage('work');
      $('[data-tile]', root)?.focus({ preventScroll: true });
      $('[data-composer]', root).scrollIntoView({ block: 'nearest' });
    } catch (error) { feedback('Реч још није сакривена.', error.message); }
    finally { pending = false; button.disabled = finished; busy(false); }
  });
  $('[data-submit-writing]', root)?.addEventListener('click', event => {
    if (writing?.complete()) submit({ letter_traces: writing.payload() }, event.currentTarget);
  });
  $('[data-submit-variety]', root)?.addEventListener('click', event => {
    if (variety?.complete()) submit({ answer: variety.answer() }, event.currentTarget);
  });
  choices.forEach(button => button.addEventListener('click', () => submit({ answer: button.dataset.answer }, button)));
  $('[data-submit-word]', root)?.addEventListener('click', event => {
    if (composer.complete()) submit({ answer: composer.answer() }, event.currentTarget);
  });
  $('[data-submit-trace]', root)?.addEventListener('click', event => {
    if (pending || finished) return;
    const result = trace.score();
    if (result.drawnLength < 15) {
      feedback('Прво напиши слово.', 'Пиши по трагу, па притисни „Провери слово”.'); return;
    }
    trace.showScore(result.score);
    submit({ trace_score: result.score, trace_metrics: {
      coverage: result.coverage, precision: result.precision, points: result.points,
      drawnLength: result.drawnLength, guideLength: result.guideLength
    } }, event.currentTarget);
  });
}

function setupComposer(root, isLocked, onStage = () => {}) {
  const box = $('[data-composer]', root), tiles = $$('[data-tile]', root), slots = $$('[data-slot]', root);
  const submit = $('[data-submit-word]', root), undo = $('[data-undo]', root);
  const status = $('[data-compose-status]', root);
  const selected = [];
  function refresh() {
    slots.forEach((slot, index) => {
      const tile = selected[index] === undefined ? null : tiles[selected[index]];
      slot.firstElementChild.textContent = tile?.textContent || '·';
      slot.classList.toggle('filled', Boolean(tile)); slot.disabled = !tile || isLocked();
      slot.classList.toggle('is-next', index === selected.length);
      slot.setAttribute('aria-label', tile ? `Врати слово ${tile.dataset.letter}` : `Место ${index + 1}, празно`);
    });
    tiles.forEach((tile, index) => {
      tile.disabled = selected.includes(index) || selected.length >= slots.length || isLocked();
      tile.classList.toggle('used', selected.includes(index));
    });
    submit.disabled = selected.length !== slots.length || isLocked();
    undo.disabled = !selected.length || isLocked();
    const remaining = slots.length - selected.length;
    status.textContent = !selected.length ? 'Додирни прво слово.' : remaining ? `Још ${remaining} ${remaining === 1 ? 'слово' : 'слова'} до целе речи.` : 'Реч је ту! Притисни „Провери реч”.';
    if (!box.hidden && !isLocked()) onStage(remaining ? 'work' : 'check');
  }
  tiles.forEach((tile, index) => tile.addEventListener('click', () => {
    if (isLocked() || selected.includes(index) || selected.length >= slots.length) return;
    selected.push(index); refresh();
    if (selected.length === slots.length) { submit.focus({ preventScroll: true }); submit.scrollIntoView({ block: 'nearest' }); }
  }));
  slots.forEach((slot, index) => slot.addEventListener('click', () => {
    if (isLocked()) return;
    selected.splice(index, 1); refresh();
  }));
  undo.addEventListener('click', () => { if (!isLocked()) { selected.pop(); refresh(); } });
  refresh();
  return { refresh, answer: () => selected.map(index => tiles[index].dataset.letter).join(''),
    complete: () => selected.length === slots.length,
    lock() { $$('button', box).forEach(button => { button.disabled = true; }); }
  };
}

function setupTrace(root, isLocked, onStage = () => {}) {
  const guide = $('.trace-guide', root);
  const submit = $('[data-submit-trace]', root), clear = $('[data-clear]', root);
  const status = $('[data-trace-status]', root), guideButton = $('[data-guide]', root);
  const pad = createTracePad($('.trace-board', root), isLocked, () => {
    $('.trace-score', root).hidden = true;
    refresh();
  });
  pad.set(JSON.parse($('#trace-data', root).textContent));
  function refresh() {
    const ready = pad.hasStroke() && !pad.drawing();
    submit.disabled = isLocked() || !ready;
    clear.disabled = isLocked() || !pad.hasInk();
    guideButton.disabled = isLocked();
    status.textContent = ready ? 'Написао си цело слово? Притисни „Провери слово”.' : 'Прати бројеве и стрелице. Подигни прст између потеза.';
    if (!isLocked()) onStage(ready ? 'check' : 'work');
  }
  clear.addEventListener('click', () => {
    if (isLocked()) return;
    pad.clear(); $('.trace-score', root).hidden = true;
  });
  function setGuide(visible) {
    guide.classList.toggle('faint', !visible); guideButton.setAttribute('aria-pressed', String(visible));
    $('span', guideButton).textContent = visible ? 'Сакриј траг' : 'Покажи траг';
  }
  guideButton.addEventListener('click', () => { if (!isLocked()) setGuide(guide.classList.contains('faint')); });
  refresh();
  return {
    refresh,
    score: pad.score,
    showGuide: () => setGuide(true),
    showScore(score) { const box = $('.trace-score', root); box.hidden = false; $('span', box).textContent = `${score}%`; }
  };
}
