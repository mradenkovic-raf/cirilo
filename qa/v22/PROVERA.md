# Provera v22 — zvuci igara, naočare i autić

Datum: 2026-10-13. Lokalna grana `school-learning`. Povratak na prethodni kod: tag `v21-stable-before-game-audio` (`acdc013`). Konzistentna rezerva glavne baze je u ignorisanom direktorijumu `revisions/2026-10-13-v21-before-game-audio/`.

## Automatske provere

`RAILS_ENV=test TEST_DATABASE_PATH=storage/v22-test.sqlite3 bin/check` prolazi: eager loading, **293 Rails testa / 93.383 tvrdnje**, **58 JavaScript testova**, bez neuspeha. Izlaz: [check.txt](check.txt).

- Naočare otkrivaju i čuvaju isti protivnikov potez za narednu rundu, uključujući ponovno otvaranje. Prikaz ostaje posle mrežne greške, retry ga koristi jednom, a posle runde nestaje. Nisu menjana pravila servera.
- Autić prati šesti originalni zadatak kada dodatna ponavljanja menjaju broj i raspored tačaka. AJAX odgovor odmah osvežava položaj i pristupačan opis. Rezultat vožnje ostaje prikazan.
- Vožnja pušta efekat samo za prihvaćeno skretanje i za svaki nov sudar. Pobeda/poraz i aplauz čekaju uspešno čuvanje rezultata; refresh ne ponavlja finale. Pauza, tab visibility, pagehide, retry i preskakanje pokriveni su testovima kontrolera.
- Arena razlikuje pogodak, promašaj, blokadu, nerešeno i moć; završna pobeda/poraz puštaju svoj signal jednom. Duplirani odgovori i ponovno otvaranje završene borbe ne ponavljaju zvuk.
- Audio modul ima 13 zasebnih testova: stvarni gest, mute i drugi tabovi, odsutan AudioContext, sakrivanje stranice, asinhroni resume, ograničen broj glasova, cleanup i Browser Back. Aplauz ima kratke odvojene stereo udarce sa numerički proverenom rezervom glasnoće; to nije slušna ocena.

## Stvarni browser

Izdvojeni server `localhost:3002` i baza `storage/v22-browser.sqlite3`; glavni server je `127.0.0.1:3001`. Probni podaci uključuju sedam delova opreme i namenski pripremljene borbe sa po jednim preostalim životom za brz pregled oba finala. Mission cursor je u probnoj bazi pomeren na šesti zadatak za otvaranje vožnje; ovaj pregled ne tvrdi da je ručno rešena cela misija.

Pri širini **320 px**:

- Klik na „Откриј потез” prikazao je veliki panel „МРГУДОВ СЛЕДЕЋИ ПОТЕЗ”, štit i status „Потез откривен”. Izbor varke zatim je zaista pobedio Mrgudov štit. [Snimak](goggles-mobile.jpg).
- Putanja pokazuje autić na polovini; širina dokumenta i viewporta je 320 px, bez horizontalnog prelivanja. [Snimak](mission-car-mobile.jpg).
- Stvarno pokrenuta vožnja, skretanje ulevo, pauza, isključivanje/uključivanje zvuka i nastavak. Posle tri sudara prikazan poraz i povratak u misiju; marker ima stanje `lost`.
- Druga probna arena završila se porazom igrača i odgovarajućim završnim ekranom.
- Tokom ovih pregleda nisu zabeležena JS upozorenja ili greške. Browser kontrola potvrđuje tok događaja, ne predstavlja slušnu proveru.

Pobeda vožnje i njen aplauz provereni su automatizovanom integracijom; browser pobeda vožnje bila je potvrđena u v21, nije ponovo ručno odigrana u ovom pregledu. Fizički telefoni i subjektivni kvalitet melodija/aplauza nisu provereni. Muzika može početi tek nakon prvog stvarnog dodira/tastera zbog pravila browsera.

## Podaci i objava

Nema migracija, novih servisa ili dodatnih audio preuzimanja. [Poređenje glavne baze](main-preservation.json) prikazuje stanje prema rezervi pre rada. Glavni `/up` vraća uspešan odgovor. Izmene su lokalne; GitHub i Railway nisu menjani.
