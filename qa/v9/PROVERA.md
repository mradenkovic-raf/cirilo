# V9 — raznovrsniji zadaci

Datum: 2026-10-11. Tri nove igre u postojećem Rails/HTML toku; bez migracija, novih servisa i frontend zavisnosti.

## Šta je promenjeno

- `picture_word`: slika i četiri stvarne reči, sa prednošću sličnih zapisa među pogrešnim izborima.
- `repair_word`: dete samo bira pogrešno mesto u reči, pa zamensko slovo. Promena mesta vraća prethodnu izmenu. Server prihvata samo jednu zamenjenu poziciju iz ponuđenih slova.
- `word_pairs`: tri reči i tri slike; dodir reči pa slike, izmena veze i vraćanje poslednje veze. Sve veze proveravaju se zajedno, za ukupno 10 XP. Neutralni brojevi ne otkrivaju tačnost pre provere. Slike nisu sve u istim redovima kao odgovarajuće reči, a АУТО i ЏИП se ne pojavljuju zajedno.
- Trojni ciklus misija zadržava svih osam vežbi pisanja/pamćenja i jednu priču; menja tri ostala mesta između starih i novih tipova. Ostaje 12 redovnih zadataka, 145 XP i najviše tri dodatna ponavljanja. Format zadatka je 5; aktivni formati 3/4 ostaju neizmenjeni.
- Nove kontrole zaključavaju se tokom zahteva, a izbor ostaje posle neuspelog čuvanja. Posle odgovora ostaju samo rezultat i sledeći korak. Ispravljen je i zajednički fokus na „Dalje”: sada se postavlja tek po završetku slanja, kada panel postane vidljiv.

## Automatske provere

`automatske-provere.txt`: eager loading i 174 Rails testa / 5.900 tvrdnji, bez grešaka ili preskakanja. Izolovana baza `storage/v9-full-test.sqlite3`. Novi testovi pokrivaju generisanje, izbor slova i parova, nevalidne zahteve bez upisa, ponavljanje, duple nagrade, ceo ciklus i očuvanje starih misija. Stari protokoli i dalje imaju izričite probne zadatke i svoje provere.

`javascript-provere.txt`: 10 testova geometrije i šest testova novih kontrola, svi prolaze. Provereni su menjanje pozicije, vraćanje originalnog slova, veliko/malo slovo, potpuni i jedinstveni parovi, premeštanje već spojene slike, undo, čuvanje izbora tokom zaključavanja i fokus. `bin/check` sada pokreće sve `test/javascript/*_test.mjs` fajlove. Prvi puni zapis prikazuje dve Node datoteke kao dve zbirne provere; poseban zapis prikazuje svih 16 pojedinačnih testova.

Nezavisan pregled nije našao funkcionalnu grešku. Dodatno je provereno generisanje 2.040 kombinacija popravke reči i 360 misija, bez upisa stvarnog napretka.

## Browser

Svi probni odgovori koriste `storage/v9-browser.sqlite3` na portu 3002. `prepare.rb` i `boundaries.rb` odbijaju drugu bazu. Prvi skript postavlja cursor na traženi zadatak; drugi pravi skraćene sintetičke zadatke za pregled šest slova. Snimak sa „1/2” ili „2/2” zato nije stvarna dužina misije.

- 320 × 740: izbor ИГЛА sa slike prihvaćen za 10 XP i prikaz značenja. Spajanje дуга/ауто/ђаво, pogrešna lokalna veza, preuzimanje iste slike drugom rečju, undo i završna provera sva tri para za 10 XP.
- Popravka нгла: izbor места pa slova, promena mesta vraća prethodnu izmenu; namerno pogrešna њгла ubacuje recovery, povećava broj koraka 12 → 13 i ne dodaje XP. Recovery je završen QA skriptom, a ponovno rešavanje originala и → игла u browseru daje 10 XP i značenje.
- Najduža reč ЛИСИЦА: svih šest mesta staje na 320 px bez horizontalnog prelivanja, sa dodirnim mestima širine najmanje 44 px. Potvrđena je i popravka na desktopu 1280 × 850.
- Parovi pregledani na desktopu, uključujući završni prikaz bez preostalih uputstava i disabled dugmeta za proveru. Fokus posle potvrde popravke izričito proverava `document.activeElement`: link „Dalje”.
- Uzorak browser upozorenja i grešaka je prazan (`browser-logs.json`). To nije provera fizičkog Android/iPhone uređaja, olovke, offline režima ili javnog hostinga.

Snimci: `picture-word-320.png`, `pairs-320.png`, `repair-word-320.png`, `repair-six-320.png`, `repair-desktop.png`, `pairs-desktop.png`, `pairs-success-desktop.png`.

## Stvarni podaci

Arhiva pre rada: `revisions/2026-10-11-v8-before-task-variety/source.tar.gz` i konzistentan SQLite backup. `main-preservation.json` potvrđuje identične redove svih osam tabela: 290 ukupnih XP, 220 potrošenih, 10 završenih misija. Nisu resetovani niti trošeni stvarni poeni.

Glavni server je ponovo učitan. Početna na portu 3000 radi i uključuje nove verzionisane CSS/JS fajlove. Privremeni viewport je uklonjen; probni tab i server su zatvoreni. Glavna početna ostaje otvorena.
