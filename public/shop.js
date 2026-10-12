import { burst } from './fx.js';

const dialog = document.querySelector('[data-shop-confirm]');
let pendingForm;
const sections = [...document.querySelectorAll('[data-shop-section]')];
const categoryLinks = [...document.querySelectorAll('[data-shop-category]')];
function showCategory() {
  const hash = window.location.hash.slice(1);
  const target = hash ? document.getElementById(hash) : null;
  const category = target?.closest('[data-shop-section]')?.dataset.shopSection ||
    document.querySelector('[data-shop-reveal]')?.dataset.revealCategory || 'dino';
  sections.forEach(section => { section.hidden = section.dataset.shopSection !== category; });
  categoryLinks.forEach(link => {
    if (link.dataset.shopCategory === category) link.setAttribute('aria-current', 'location');
    else link.removeAttribute('aria-current');
  });
  // Direct item links can point into a collapsed collection. Reveal the target
  // before scrolling, while category changes keep the tabs on screen.
  if (target?.matches('[data-shop-card]')) {
    let drawer = target.closest('details');
    while (drawer) {
      drawer.open = true;
      drawer = drawer.parentElement.closest('details');
    }
    requestAnimationFrame(() => target.scrollIntoView({ block: 'start' }));
  }
}
if (sections.length) {
  showCategory();
  window.addEventListener('hashchange', showCategory);
}

if (dialog) {
  window.addEventListener('pageshow', event => {
    // Back/forward cache can otherwise restore the old balance and submitted form.
    if (event.persisted) window.location.reload();
  });
  document.querySelectorAll('[data-shop-buy]').forEach(button => {
    button.form.addEventListener('submit', event => {
      if (!dialog.showModal || button.form.dataset.confirmed === 'true') return;
      event.preventDefault();
      pendingForm = button.form;
      dialog.querySelector('[data-confirm-purchase]').disabled = false;
      dialog.querySelector('[data-confirm-purchase]').textContent = 'Да, откључај!';
      const card = button.closest('[data-shop-card]');
      dialog.querySelector('[data-confirm-name]').textContent = card.querySelector('h3').textContent;
      dialog.querySelector('[data-confirm-price]').textContent = button.querySelector('b').textContent;
      const art = card.querySelector('.shop-card-art').cloneNode(true);
      art.querySelector('.shop-card-state')?.remove();
      // Previews have no controls; cloning their SVG keeps the confirmation recognizable.
      dialog.querySelector('[data-confirm-art]').replaceChildren(art);
      const price = Number(button.querySelector('b').textContent.replace(/[^0-9]/g, ''));
      const balance = Number(document.querySelector('.shop-wallet > strong').firstChild.textContent.trim());
      dialog.querySelector('[data-confirm-balance]').textContent = `После куповине остаје ти ${balance - price} XP.`;
      dialog.showModal();
      dialog.querySelector('[data-confirm-purchase]').focus();
    });
  });
  dialog.querySelectorAll('[data-close-confirm]').forEach(button => button.addEventListener('click', () => dialog.close()));
  dialog.querySelector('[data-confirm-purchase]').addEventListener('click', event => {
    if (!pendingForm || event.currentTarget.disabled) return;
    event.currentTarget.disabled = true;
    event.currentTarget.textContent = 'Откључавамо…';
    pendingForm.dataset.confirmed = 'true';
    pendingForm.requestSubmit();
  });
  dialog.addEventListener('close', () => { pendingForm = null; });
}

const reveal = document.querySelector('[data-shop-reveal]');
if (reveal) {
  let alreadyShown = false;
  try {
    const key = `cirilo-unlocked-${reveal.dataset.shopGeneration}-${reveal.dataset.shopReveal}`;
    alreadyShown = sessionStorage.getItem(key) === 'shown';
    sessionStorage.setItem(key, 'shown');
  } catch { /* The server flash still limits the reveal without storage. */ }
  if (!alreadyShown) {
    if (reveal.showModal) reveal.showModal(); else reveal.setAttribute('open', '');
    burst({ kind: 'unlock', origin: reveal.querySelector('.reveal-art'), label: 'ОТКЉУЧАНО!' });
  }
  reveal.querySelector('[data-close-reveal]').addEventListener('click', () => {
    if (reveal.close) reveal.close(); else reveal.removeAttribute('open');
    document.querySelector('.shop-tabs a[aria-current]')?.focus({ preventScroll: true });
  });
}
