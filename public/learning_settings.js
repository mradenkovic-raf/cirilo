const settings = document.querySelector('[data-learning-settings]');
if (settings) {
  const school = settings.querySelector('[data-school-selection]');
  const through = settings.querySelector('[data-through-letter]');
  const letters = [...settings.querySelectorAll('[data-school-letter]')];
  const preview = settings.querySelector('[data-school-letter-preview]');
  function update() {
    school.hidden = settings.querySelector('[name="learning_mode"]:checked')?.value !== 'school';
    const cumulative = settings.querySelector('[name="letter_selection"]:checked')?.value === 'through';
    if (cumulative) {
      const last = letters.findIndex(letter => letter.value === through.value);
      letters.forEach((letter, index) => { letter.checked = index <= last; });
    }
    const chosen = letters.filter(letter => letter.checked);
    preview.textContent = chosen.length ? chosen.map(letter => letter.dataset.schoolLetter).join(' · ') : 'Изабери бар једно слово.';
  }
  through.addEventListener('change', () => {
    settings.querySelector('[name="letter_selection"][value="through"]').checked = true;
    update();
  });
  letters.forEach(letter => letter.addEventListener('change', () => {
    settings.querySelector('[name="letter_selection"][value="custom"]').checked = true;
    update();
  }));
  settings.querySelectorAll('[name="learning_mode"],[name="letter_selection"]').forEach(input => input.addEventListener('change', update));
  update();
}
