import fs from 'node:fs/promises';
import { guidePathData, guideAnnotations } from '../../public/trace.js';

const alphabet = JSON.parse(await fs.readFile(new URL('../../config/alphabet.json', import.meta.url), 'utf8'));
for (let page = 0; page < 3; page++) {
  let cells = '';
  alphabet.slice(page * 10, page * 10 + 10).flatMap(letter => ['upper', 'lower'].map(form => ({ letter, form })))
    .forEach(({ letter, form }, index) => {
      const strokes = letter.strokes[form];
      const x = index % 4 * 200 + 20, y = Math.floor(index / 4) * 205 + 35;
      let paths = guidePathData(strokes).map(d => `<path d="${d}"/>`).join('');
      guideAnnotations(strokes).forEach(({ start, badge, arrow }, order) => {
        if (arrow) paths += `<path class="direction" d="${guidePathData([arrow])[0]}"/>`;
        if (start !== badge) paths += `<path class="leader" d="${guidePathData([[badge, start]])[0]}"/>`;
        paths += `<circle cx="${badge[0]}" cy="${badge[1]}" r="3.5"/><text class="number" x="${badge[0]}" y="${badge[1]+1.4}">${order+1}</text>`;
      });
      cells += `<g transform="translate(${x} ${y})"><text x="80" y="-12" class="label">${letter[form]}</text><g transform="scale(1.6)"><rect width="100" height="100" rx="8"/>${paths}</g></g>`;
    });
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="1040" viewBox="0 0 800 1040"><style>
    svg{background:white}rect{fill:#fbfcf7;stroke:#e1e7d8}path{fill:none;stroke:#d3dfbc;stroke-width:6;stroke-linecap:round;stroke-linejoin:round}
    path.direction{stroke:#567b36;stroke-width:1.6}path.leader{stroke:#8fa774;stroke-width:1}
    circle{fill:#a2c965;stroke:#fffdf4;stroke-width:1.3}.number{font:900 4px sans-serif;fill:#486b30;text-anchor:middle}.label{font:700 22px sans-serif;fill:#344b2d;text-anchor:middle}
  </style>${cells}</svg>`;
  await fs.writeFile(new URL(`guides-${page+1}.svg`, import.meta.url), svg);
}
