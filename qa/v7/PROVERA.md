# Provera v7 — 11. oktobar 2026.

Dodato je dvorište sa stvarno spasenim drugarima i poseban potpuni restart u roditeljskim opcijama. Bez migracija, novih servisa i govornog vodiča.

## Automatske provere

- `automatske-provere.txt`: eager loading, 155 Rails testova / 3.179 tvrdnji, 10 JavaScript geometrijskih provera. Nema neuspeha, grešaka ili preskakanja. Izdvojena `storage/v7-full-test.sqlite3`.
- Ciljano: 36 reset/arena testova / 526 tvrdnji na `storage/v7-reset-test.sqlite3`; osam workshop/mapa testova / 165 tvrdnji na `storage/v7-friends-test.sqlite3`. Proverene granice spasavanja 0–24, odgovarajući drugari i aktivnosti, odsustvo XP od prikaza/pozdrava, sva polja restarta, rollback, ponovljeni zahtevi, stare misije/borbe i konkurentni reset sa odgovorom ili potezom u areni.
- Sintaksa `public/workshop.js` proverena Node-om.
- `production-check.txt`: nova `storage/v7-production.sqlite3`, Rails/Rack sa stvarnom CSRF zaštitom. Sintetički odgovori pripremaju 16 misija, opremu, borbu, kupovinu, zamene slova i rezervu opreme. Pogrešan CSRF daje očekivani 422, pogrešna potvrda ne menja podatke. Validan restart briše sve grupe podataka, vraća mapu/prikaz na nulu i početni izgled. Stari ID-jevi daju očekivani 404, staro vraćanje opreme ne uspeva, nove početne vežbe ponovo donose XP, a ponovljeni stari restart ne briše tih novih 10 XP. Očekivane 422/404 greške su zabeležene u logu; završni ishod je PASS.

## Browser

Lokalni probni server na 3002 koristi isključivo `storage/v7-browser.sqlite3`. `prepare.rb` i `reset_preview.rb` odbijaju drugu putanju baze. Početni podaci su sintetički: 16 misija, 16 delova, četiri drugara, 2.320 XP, kupljen svemir i 2.100 raspoloživih XP. Cele misije nisu odigrane rukom.

- Desktop 1280 px: četiri drugara oko Klika, različiti rekviziti i aktivnosti. Liskov dodir daje zahvalnost za spasavanje iz šume.
- Na 320 px provereni su i Iskrin, Žarkov i Zvezdanov pozdrav. Dugmad drugara su oko 80 × 105 px, iznad minimuma za dodir; sadržaj je 305 px. Nema zabeleženih JavaScript grešaka.
- Roditeljski formular ima jasno navedeno brisanje mape i drugara, sve uređaje i odsustvo poništavanja. Obavezni checkbox i tekst sa obrascem `RESET`; sadržaj na 320 px je 305 px. Validno brisanje nije pokretano browser klikom.
- `reset-preview.txt`: potpuni restart izvršen servisom isključivo nad probnom bazom. Svih sedam grupa podataka ima nula redova; XP, potrošnja i misije su nula. Posle browser osvežavanja dvorište nema spasenih drugara, nudi prvog Liska za četiri misije, a mapa je 0/16 i 0/4.
- Glavni server je ponovo učitan posle dorade. Radionica na portu 3000 prikazuje stvarna dva spasena drugara, Liska i Iskru, sledećeg Žarka za dve misije i postojećih 70 raspoloživih XP. Prikaz je samo čitan, bez JS grešaka. Probni server je ugašen, privremena veličina prozora vraćena i glavna radionica ostavljena otvorena.

Snimci: `friends-desktop.png`, `friends-320.png`, `parent-reset-320.png`, `empty-after-reset-320.png`, `map-after-reset-320.png`. Probni prikazi predstavljaju probne podatke. `main-friends-desktop.png` prikazuje glavnu aplikaciju sa stvarnim ranije spasenim drugarima.

## Sačuvani stvarni podaci i granice

Arhiva pre rada: `revisions/2026-10-11-v6-before-friends/source.tar.gz` i konzistentni SQLite backup. `main-preservation.json` potvrđuje nepromenjene redove svih osam tabela u glavnoj bazi: 290 ukupnih XP, 220 potrošeno, 10 završenih misija. Stvarni napredak nije resetovan niti korišćen za probne odgovore ili borbe.

Ovo je lokalni Chromium pregled, ne fizički Android/iPhone ili provera olovke. Production provera je Rails/Rack, ne javni hosting. Smanjeno kretanje provereno je kroz CSS/JS pravila, a ne na fizičkom uređaju. Mute je deo postojećeg zajedničkog sistema efekata.
