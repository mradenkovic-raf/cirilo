# Provera prve verzije — 2026-10-11

## Automatski

`bin/check`: Rails eager load, 21 test sa 244 assertions i 10 JS testova geometrije. Sve prolazi. Testovi koriste `storage/test.sqlite3`, odvojeno od napretka otvorenog u aplikaciji. Production smoke koristi `storage/production-smoke.sqlite3` i privremeno generisan secret; proveren HTTP 200.

## Browser

Izolovan lokalni server na portu 3001, baza `storage/browser-test.sqlite3`. Stvarni ugrađeni Chromium, ručni browser unos i povlačenje pokazivača; bez neposrednog menjanja odgovora kroz JavaScript.

| Provera | Ishod |
| --- | --- |
| Nova misija | 10 zadataka, početna slova А/М/И |
| Pogrešan izbor | Ostaje isti zadatak, bez dodatnog XP, ohrabrenje |
| Tačan izbor | +10 XP, dugme za sledeći zadatak |
| Prazno polje pisanja | Traži da se slovo najpre napiše |
| Potezi van oblika | Nizak rezultat, ponavljanje bez nagrade |
| Praćenje М, и, А | Stvarni potezi mišem, 100%, prelazak dalje |
| Par veliko/malo | Pravilno čuva odgovor |
| Dopuna МАЧКА i АВИОН | Prikaz reči bez prvog slova, slika, izbor |
| Izgovor bez srpskog glasa | Jasno obaveštenje, ostatak igre radi |
| Završetak misije | 125 XP ukupno, otključane Турбо чизмице |
| Radionica | Čizme vidljive na dinosaurusu i u kolekciji |
| Plava boja + osvežavanje | Izbor ostaje sačuvan |
| 390 px | Proveren prikaz igre i početne strane, bez preklapanja u završnoj verziji |
| 320 px | Slovarica 30 kartica, dva stupca, bez horizontalnog prelivanja |
| 768 px | Radionica bez horizontalnog prelivanja |

Nije testiran fizički dodir, olovka, Android Chrome ili iPhone Safari. Desktop pregled uskog ekrana potvrđuje raspored i mouse/pointer putanju, ne celokupno ponašanje mobilnog uređaja.

## Snimci

- `home-desktop.jpg`: početni ekran, probni plavi dinosaur sa prvim delom.
- `home-mobile.jpg`: početni ekran na 390 px.
- `tracing-mobile.jpg`: uspešno praćenje slova М u probnoj misiji.
- `reward-mobile.jpg`: potvrda osvojene nagrade.
- `workshop-mobile.jpg`: radionica i zapamćena boja.
- `alphabet-small-mobile.jpg`: slovarica na 320 px.
- `dino-blue.png`, `dino-peach.png`: zasebni vizuelni pregledi palete.

Browser provera je u jednom trenutku prekinuta gašenjem probnog servera. Napredak je ostao u SQLite bazi; server je ponovo pokrenut, HTTP 200 potvrđen i završni rasporedi ponovo otvoreni. Glavni pregled na portu 3000 nije resetovan.
