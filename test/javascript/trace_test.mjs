import { readFile } from "node:fs/promises";
import assert from "node:assert/strict";
import test from "node:test";

const source = await readFile(new URL("../../public/trace.js", import.meta.url), "utf8");
const { scoreTrace, guidePathData, guideAnnotations } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);
const alphabet = JSON.parse(await readFile(new URL("../../config/alphabet.json", import.meta.url), "utf8"));
const letterA = alphabet[0].strokes.upper;

test("all 30 Serbian letters have words and finite uppercase/lowercase print guides", () => {
  assert.equal(alphabet.map((letter) => letter.upper).join(""), "АБВГДЂЕЖЗИЈКЛЉМНЊОПРСТЋУФХЦЧЏШ");
  assert.equal(new Set(alphabet.map((letter) => letter.id)).size, 30);
  for (const letter of alphabet) {
    assert.equal(letter.lower, letter.upper.toLowerCase());
    assert.ok(letter.word.startsWith(letter.upper), `${letter.upper}: word begins with the letter`);
    for (const form of ["upper", "lower"]) {
      const paths = letter.strokes[form];
      assert.ok(paths.length > 0);
      for (const path of paths) {
        assert.ok(path.length >= 2);
        for (const point of path) {
          assert.equal(point.length, 2);
          assert.ok(point.every((value) => Number.isFinite(value) && value >= 0 && value <= 100));
        }
      }
      assert.equal(scoreTrace(paths, paths).score, 100, `${letter.upper} ${form}: exact trace`);
    }
  }
});

test("empty drawings, taps and tiny marks do not pass", () => {
  for (const drawing of [[], [[[50, 50]]], [[[50, 50], [50, 50]]], [[[50, 50], [51, 51]]]]) {
    assert.equal(scoreTrace(letterA, drawing).score, 0);
  }
});

test("school guides separate strokes and direct straight stems downwards", () => {
  for (const letter of alphabet) {
    for (const [form, paths] of Object.entries(letter.strokes)) {
      for (const path of paths) {
        if (path.length === 2 && path[0][0] === path[1][0]) {
          assert.ok(path[1][1] > path[0][1], `${letter[form]}: straight stem goes down`);
        }
      }
      if ('ГИМПШ'.includes(letter.upper)) assert.ok(paths.length >= 2, `${letter[form]}: lift between strokes`);
      if (letter.upper === 'О') assert.ok(paths[0][1][0] < paths[0][0][0], `${letter[form]}: oval starts towards the left`);
    }
  }
  assert.equal(letterA.length, 3, 'А has two separate slants and a crossbar');
  assert.deepEqual(letterA[0][0], letterA[1][0], 'both slants start at the apex');
  assert.ok(letterA[0].at(-1)[1] > letterA[0][0][1]);
  assert.ok(letterA[1].at(-1)[1] > letterA[1][0][1]);
});

test("small hand wobble passes, large displacement does not", () => {
  const translate = (dx, dy) => letterA.map((path) => path.map(([x, y]) => [x + dx, y + dy]));
  assert.ok(scoreTrace(letterA, translate(3, 2)).score >= 65);
  assert.ok(scoreTrace(letterA, translate(18, 15)).score < 65);
});

test("a missing stroke cannot be replaced by repeating another stroke", () => {
  const missingBar = [letterA[0]];
  assert.ok(scoreTrace(letterA, missingBar).score < 65);
  assert.ok(scoreTrace(letterA, Array.from({ length: 6 }, () => letterA[0])).score < 65);
});

test("filling the whole board with scribbles does not pass", () => {
  const scribble = [];
  for (let y = 0; y <= 100; y += 4) scribble.push([0, y], [100, y]);
  const result = scoreTrace(letterA, [scribble]);
  assert.ok(result.coverage > 0.8, "scribble touches the guide");
  assert.ok(result.score < 65, "touching a guide is not enough");
  assert.ok(scoreTrace(letterA, [...letterA, scribble]).score < 65);
});

test("an unrelated shape does not pass", () => {
  const circle = alphabet.find((letter) => letter.upper === "О").strokes.upper;
  assert.ok(scoreTrace(letterA, circle).score < 65);
});

test("stroke direction and stroke order do not affect a complete trace", () => {
  const reversed = letterA.toReversed().map((path) => path.toReversed());
  assert.equal(scoreTrace(letterA, reversed).score, 100);
});

test("separate drawn paths are not connected across a lifted pointer", () => {
  const left = [[[10, 20], [10, 80]]];
  const right = [[[90, 20], [90, 80]]];
  const middle = [[[30, 65], [70, 35]]];
  assert.equal(scoreTrace(middle, [...left, ...right]).score, 0);
});

test("the dot of printed ј can be tapped, while dots alone cannot draw a letter", () => {
  const guide = alphabet.find((letter) => letter.lower === "ј").strokes.lower;
  assert.ok(scoreTrace(guide, [guide[0], [[57, 26]]]).score >= 99);
  const taps = guide.flat().map((point) => [point]);
  assert.equal(scoreTrace(guide, taps).score, 0);
});

test("malformed input is safe and guide paths remain separate SVG paths", () => {
  assert.equal(scoreTrace(null, undefined).score, 0);
  assert.equal(scoreTrace(letterA, [[null, [NaN, Infinity]]]).score, 0);
  assert.equal(guidePathData(letterA).length, letterA.length);
  assert.equal(guidePathData([[[2, 3], [4, 5]]])[0], "M2 3 L4 5");
});

test("direction arrows follow straight and curved paths; a dot has no arrow", () => {
  const down = guideAnnotations([[[20, 20], [20, 80]]])[0].arrow;
  assert.ok(down[1][1] > down[0][1] && down[1][1] > down[2][1]);
  const left = guideAnnotations([[[80, 20], [20, 20]]])[0].arrow;
  assert.ok(left[1][0] < left[0][0] && left[1][0] < left[2][0]);
  const curve = guideAnnotations([[[50, 20], [40, 25], [30, 40], [25, 60]]])[0].arrow;
  assert.ok(curve[1][0] < (curve[0][0] + curve[2][0]) / 2);
  assert.ok(curve[1][1] > (curve[0][1] + curve[2][1]) / 2);
  assert.equal(guideAnnotations([[[56, 26], [58, 26]]])[0].arrow, null);
});

test("stroke numbers at the same start remain separate and inside the pad", () => {
  const hints = guideAnnotations([[[28, 20], [28, 80]], [[28, 20], [70, 40]]]);
  assert.deepEqual(hints[0].start, hints[1].start);
  assert.ok(Math.hypot(hints[0].badge[0] - hints[1].badge[0], hints[0].badge[1] - hints[1].badge[1]) >= 8);
  for (const letter of alphabet) {
    for (const paths of Object.values(letter.strokes)) {
      for (const { badge, arrow } of guideAnnotations(paths)) {
        for (const point of [badge, ...(arrow || [])]) {
          assert.ok(point.every((value) => Number.isFinite(value) && value >= 0 && value <= 100));
        }
      }
    }
  }
});
