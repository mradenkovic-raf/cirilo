# V12 — srca i pojedinačni komadi oklopa

`check.txt`: 186 Rails testova / 6.137 tvrdnji i 26 JavaScript testova, bez neuspeha. Izolovana baza `storage/v12-full-test.sqlite3`. Posle kratke završne izmene početne poruke ponovljene su ciljane provere kontrolera (`final-controller-check.txt`).

Provereni su broj srca i stvarnih komada oklopa, odsustvo lažnog komada kod dinosaurusa bez opreme, prelaz poslednji oklop → tri srca → dva srca, odgovarajuće poruke posle ponovnog učitavanja i očuvana kolekcija. JS testovi izvršavaju stvarni arena kontroler i proveravaju da samo izgubljena ikona dobija animaciju; nema lažnog oštećenja kod nerešenog poteza, štita, izbegavanja, istog stanja i duplog odgovora. Postojeće završnice i mute provere i dalje prolaze.

Browser koristi samo `storage/v12-browser.sqlite3` na 3002. `prepare.rb` odbija bilo koju drugu bazu; sintetičke borbe imaju 1 i 16 delova opreme. Dva stvarna klika na Удар protiv pripremljenog Штит poteza potvrđuju gubitak oklopa uz tri srca, zatim gubitak srca. Na širini 320 px vidljivi su veća srca, prsluci oklopa i jasna poruka; puna oprema ne preliva horizontalno. Desktop pregled 1280 px takođe prolazi. Browser nije prijavio JS greške.

Snimci `armor-hearts-320.png`, `armor-lost-320.png`, `heart-lost-320.png`, `full-armor-320.png` i `full-armor-desktop.png` predstavljaju probnu bazu. Fizički telefon nije dodatno proveren.

`main-preservation.json` potvrđuje da su sve tabele glavne baze identične snimku pre rada. Arhiva izvora i konzistentne baze je `revisions/2026-10-11-v11-before-arena-icons/`. Nema migracija, novih servisa ili promena pravila borbe/XP. Probni server je zaustavljen, probni tab zatvoren i viewport vraćen.
