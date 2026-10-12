# V15 — zaseban napredak svakog browsera

Datum: 2026-10-12. Korisnik je izabrao da svi browseri krenu od nule, a raniji zajednički napredak ostane u rezervi. Nema prijave, naloga, imena korisnika niti automatskog preuzimanja stare igre.

## Šta je promenjeno

`ApplicationController` pre akcije pronalazi učenika pomoću šifrovanog trajnog kolačića `cirilo_device`. Ključ ima 256 nasumičnih bitova; baza čuva samo SHA-256 otisak sa jedinstvenim indeksom. Cookie ima `HttpOnly`, `SameSite=Lax`, putanju `/` i `Secure` preko HTTPS-a, obavezno u production režimu. Rails podešava trajanje na 20 godina i obnavlja ga pri poseti, ali browser može da ga obriše ranije.

GET/HEAD sa nepoznatim ključem otvara novi prazan zapis i resetuje Rails sesiju. POST/PATCH sa nevažećim ili nedostajućim ključem vraća 422, bez novog učenika ili promene napretka. Stari CSRF token ne važi za novu igru. Sve akcije koriste `current_learner` i njegove asocijacije, bez `Learner.current` ili globalnog fallback-a. Tuđe misije i borbe vraćaju 404. Odgovori imaju `Cache-Control: no-store`.

Migracija `20261012000100` uklanja singleton ograničenje i dodaje jedinstveni digest. Stari učenik ostaje sa `NULL` digestom: nijedan browser ne dobija pristup tom zapisu. Migracija se namerno ne vraća sa `db:rollback`, jer se više odvojenih igara ne može bezbedno stopiti u jednu. Za povratak se koriste stari kod i rezervna baza zajedno.

Roditeljski tekstovi objašnjavaju da reset važi samo za trenutni browser. Ključ prikaza shop proslave u sessionStorage uključuje i učenika, da nova igra u istom tabu ne nasledi oznaku već prikazane nagrade.

## Provere

- `bin/check`: **215 Rails testova / 12.809 tvrdnji**, bez grešaka; eager loading i **29 JavaScript testova** prolaze. [Pun zapis](check.txt). Test baza: `storage/v15-full-test.sqlite3`.
- Od toga je 17 novih integracionih testova / 300 tvrdnji: odvojeni cookie jarovi, povratak bez Rails sesije, HEAD, obrisan/izmenjen/nepoznat cookie, zabrana anonimnog upisa, strani ID-jevi, samostalni odgovori, XP, kupovine, izgled, jaje, borbe i sva tri reseta. Porede se svi podaci drugog učenika i njegovih sedam asocijacija.
- Dva nova testa uključuju stvarnu CSRF zaštitu i vraćaju podešavanje u `ensure`: nedostajući token se odbija; stari token posle novog browser identiteta ne može da resetuje novu igru, a nov validan token može.
- Zaseban production Rails/Rack proces sa HTTPS zahtevima, uključenim SSL podešavanjima i CSRF zaštitom: dva browsera, zaštićeni cookie, nova misija, 404 za tuđu misiju, nezavisna boja, povratak samo sa trajnim cookie-jem i odbijen upis bez CSRF-a. [Skripta](production_check.rb), [rezultat](production-check.txt). Baza `storage/v15-production.sqlite3` je isključivo probna. Ovo proverava production Rails ponašanje; nije javni hosting niti test stvarnog TLS proxy-ja.
- Kopija stvarne v14 baze uspešno migrirana. Svaki raniji red i svaka zadržana kolona ostali su identični: 1 učenik, 60 odgovora, 4 borbe, 7 zapisa slova, 4 dela, 5 misija, 0 zabuna i 0 kupovina. SQLite integritet i strani ključevi prolaze. [Poređenje kopije](upgrade-preservation.json).
- Ista provera prošla je posle migracije glavne baze. Browser na portu 3001 dobio je jedan novi učenik sa 0 XP, 0 misija i bez zavisnih podataka; osvežavanje ne pravi dodatni zapis. Stari redovi ostaju identični arhivi. [Očuvanje glavne baze](main-preservation.json), [novi početak](main-fresh-browser.json).
- U stvarnom in-app browseru na izdvojenoj `localhost:3002` bazi: „Igraj” otvara misiju; zatvaranje taba i novi tab nude „Nastavi” za istu misiju. Roditeljski pregled pokazuje novi opseg resetovanja. Glavni `127.0.0.1:3001` browser potvrđuje prazan početak posle osvežavanja; na njemu nije odigran zadatak, borba niti reset. Probni server 3002 je zaustavljen.
- Nezavisan pregled kontrolera, servisa, modela i migracije nije našao blokirajuće curenje podataka ili fallback na ranijeg učenika. `git diff --check` prolazi.

Prve dve istovremene posete browsera bez cookie-ja mogu napraviti dva prazna zapisa; poslednji odgovor postavlja važeći cookie. Ovo ne meša napredak, a eventualni stariji formular traži osvežavanje. Za prave telefone nije ponavljano fizičko testiranje; funkcija koristi standardne first-party browser kolačiće.

Snimci lokalnog pregleda: [novi početak](main-fresh-browser.png), [roditeljske opcije](parent-browser.png). Slike nisu u Gitu. Bundler je tokom provera automatski koristio privremene foldere u `/tmp`; početni dijagnostički zapis migracije bio je `/tmp/mica-v15-migrate.log`. Trajni rezultati su u ovom folderu.

## Git i povratak

Pre izmene inicijalizovan je lokalni Git:

- commit `ce45f7f` i tag `v14-stable-before-device-progress` čuvaju radnu v14;
- grana `main` ostaje na toj tački;
- nova implementacija je na grani `device-progress`;
- `revisions/2026-10-12-v14-before-device-progress/source.tar.gz` je dodatna kopija izvora;
- `revisions/2026-10-12-v14-before-device-progress/development.sqlite3` je konzistentan SQLite backup starog napretka.

Baze, lokalni runtime, tajni ključevi i arhive nisu u Gitu. Nema udaljenog repozitorijuma niti objavljivanja.

Za stvarni povratak prvo zaustaviti sve servere koji pišu u glavnu bazu, sačuvati eventualne nove izmene u Gitu i napraviti još jedan konzistentan backup **trenutne v15 baze** u novi arhivski folder. Zatim:

1. Proveriti čist radni direktorijum (`git status --short`) i preći na sačuvani kod: `git switch --detach v14-stable-before-device-progress`.
2. Vratiti celu arhiviranu v14 bazu na `storage/development.sqlite3` pomoću SQLite backup API-ja/komande. Ne kopirati samo glavni fajl dok postoji otvorena veza ili aktivni WAL. Vraćanje baze se radi uz ugašen server; trenutni v15 backup ostaje sačuvan za povratak.
3. Pokrenuti stari kod sa tom starom bazom, npr. `PORT=3001 BIND=0.0.0.0 bin/dev`, i proveriti radionicu i započetu misiju. V14 ponovo ima jednu zajedničku igru sa stanjem iz arhive.

Za povratak na v15 ponovo zaustaviti server, izabrati `git switch device-progress`, vratiti sačuvanu v15 bazu i pokrenuti aplikaciju. Sačuvati isti `SECRET_KEY_BASE` (lokalno `tmp/local_secret.txt`) da već izdati kolačići mogu da se pročitaju. Povratak kroz obe verzije nije izvršavan nad glavnom bazom; provereni su tag, arhivski fajlovi i nadogradnja kopije.
