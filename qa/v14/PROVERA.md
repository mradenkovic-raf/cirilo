# Potezi slova i više reči — v14, 2026-10-12

## Promene

- Pregledano svih 60 oblika štampane ćirilice, promenjena 42 skupa poteza. Izvori, izbor numeracije i konkretni nalazi za svaki par slova nalaze se u [IZVORI-POTEZA.md](IZVORI-POTEZA.md). Atlasi `guides-1.svg` do `guides-3.svg` i istoimeni PNG prikazuju svih 60 oblika sa brojevima i strelicama; `render-guides.mjs` ih generiše iz stvarnog kataloga i funkcije za pozicije strelica.
- Banka proširena sa 38 na 112 reči. Svako slovo ima najmanje tri početna primera; većina četiri, К pet. Tri reči imaju osam slova: ЕПРУВЕТА, ФЛАМИНГО, ЧОКОЛАДА; ostale 3–6. Za retka slova postoje i apstraktniji primeri ЉУБАВ/ЉУТО/ЊУХ sa rečenicom o značenju. Dodate grupe koje sprečavaju međusobno nuđenje semantički sličnih slika.
- Stare misije u prikazu dobijaju aktuelne putanje i za sva ponuđena slova dopune. Sačuvani JSON, IDs, odgovori, cursor i XP ostaju isti. Nove reči bira sledeća misija.
- Mobilni prikaz prilagođen dugim rečima pri pisanju, sastavljanju, čitanju, ponuđenim rečima, popravci i povezivanju parova.

## Automatske provere

- `TEST_DATABASE_PATH=storage/v14-full-test.sqlite3 bin/check`: **198 Rails testova / 12.317 tvrdnji**, bez neuspeha, grešaka ili preskočenih testova; eager loading prolazi. **29 JavaScript testova**, svi prolaze. Zapis `check.txt`.
- Posle završne dorade prikaza: `learning_flow_test`, `writing_guides_test`, `variety_flow_test` — **16 testova / 302 tvrdnje**, bez grešaka. `final-view-check.txt`.
- Dodatne provere crtaće površine i celih reči: **5/5**, `writing-controls.txt`. Prazno polje i tačka ne završavaju slovo; sva slova moraju da budu gotova, brisanje čuva druga slova, slanje zaključava kontrole.
- Nove provere pokrivaju početne reči i pun ciklus rotacije za svih 30 slova, isključivanje već izabrane reči, nedvosmislene slike, osvežavanje starih tragova bez promene napretka, odvojene poteze i smer uspravnih linija, А/О, smer strelica na krivama i razmak brojeva kod zajedničkog početka.

## Browser

Isključivo izdvojena baza `storage/v14-browser.sqlite3`, probni server na `127.0.0.1:3002`. `prepare.rb` ima zaštitu za tačnu putanju baze. Početna priprema je korigovana zbog jedinstvenog aktivnog zadatka po detetu; svi primeri sada se nalaze u jednoj probnoj misiji. Prikaz nekih primera biran je kontrolisanim pomeranjem QA cursor-a, što nije stvarno rešavanje tih zadataka.

- Na 320 × 740 stvarno ispisano А sa tri odvojena povlačenja miša: **100%**, 10 probnih XP i vidljiv prelaz dalje. `letter-a-320.png`, `letter-a-written-320.png`.
- ФЛАМИНГО: svih osam polja čitljivo uz sliku; promena na treće slovo А pravilno menja trag. Nema horizontalnog prelivanja (scrollWidth305 uz viewport320). `flamingo-320.png`. Proveren i desktop: `flamingo-desktop.png`.
- ЧОКОЛАДА u parovima ostaje u jednom redu; sve tri reči i slike čitljive na320. `word-pairs-320.png`.
- ЕПРУВЕТА u popravci ima svih osam mesta u jednom redu. Dodir pogrešnog prvog slova otvara četiri mogućnosti. `repair-320.png`.
- ЧОКОЛАДА u izboru naziva slike ima četiri velika odgovora u jednoj koloni, bez lomljenja reči. `picture-word-320.png`.
- Nema zabeleženih JS grešaka. Glavna aplikacija na3001 otvorena je samo za proveru početne strane; na glavnoj bazi nisu rešavani probni zadaci.

## Podaci i granice

Izvor i konzistentna SQLite kopija pre rada: `revisions/2026-10-12-v13-before-strokes-words/`. Svi redovi svih deset glavnih tabela identični su arhivi: `main-preservation.json`. Nema migracije ni reseta. Rails/Bundler je pri proverama koristio privremene fascikle u `/tmp`; sav QA sadržaj ostaje u ovom projektu.

Brojevi i strelice vode pisanje; procena crteža i dalje proverava oblik, a ne školski redosled/smer dečjih poteza. Među bukvarima postoje varijante; nije tvrđen jedini dopušteni rukopis. Nisu testirani fizički telefon/olovka ni pedagoški učinak. Nije ručno rešena cela nova banka reči.
