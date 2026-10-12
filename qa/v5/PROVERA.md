# Provera v5 — redosled kupovine, roditeljski reset i dečji ekrani

Datum: 2026-10-11. Aktuelna aplikacija je v5; raspored i pravila učenja ostaju v3. Ovo je evidencija onoga što je stvarno provereno. Raniji nalazi su u `qa/v4/PROVERA.md` i `qa/v3/PROVERA.md`.

## Sačuvano stanje i granice baza

Pre dorade sačuvani su izvor i konzistentan snimak glavne baze:

- `revisions/2026-10-11-v4-before-ux/source.tar.gz`
- `revisions/2026-10-11-v4-before-ux/development.sqlite3`

Šesta migracija dodaje `shop_generation`, početno 1. Primenjena je na glavnu bazu bez resetovanja. Pri read-only poređenju glavna baza i arhiva imaju 1.110 ukupnih XP, potrošeno 0, osam završenih misija, peach boju, reksa, livadu, zvezdice i nula kupovina. To je snimak u trenutku čitanja. Naš QA nije trošio niti resetovao stvarni XP.

Browser koristi izdvojenu `storage/v5-browser.sqlite3`. Backend ciljane provere koriste `storage/v5-backend-test.sqlite3`, a production provera `storage/v5-production.sqlite3`. Te baze nisu stvarni napredak deteta. Skripte za pripremu i reset proveravaju tačan put QA baze pre upisa.

## Implementirana pravila

Svaka kategorija prodavnice ima zaseban redosled:

| Kategorija | Redosled |
| --- | --- |
| Dinosaurusi | Reks → triceratops 240 XP → stegosaurus 420 XP → robo-dino 600 XP |
| Kupovne boje | Ledena 120 XP → lava 120 XP → kosmička 180 XP |
| Svetovi | Livada → svemir 220 XP → vulkan 260 XP → okean 220 XP |
| Proslave | Zvezdice → munje 160 XP → komete 220 XP |

Zelena, plava i breskva ostaju besplatne. Za novu kupovinu server traži sve ranije plaćene izbore iste kategorije. Kasniji izbor kupljen u staroj verziji ostaje dostupan i kada prethodnici nisu kupljeni. Ukupno zarađeni XP i nivo ne smanjuju se kupovinom; raspoloživi XP je ukupni umanjen za potrošeni.

Oba reseta su na roditeljskom pregledu, izvan dečje radionice. Reset dinosaurusa čuva kupovine i XP. Poseban reset XP-a i prodavnice traži označenu potvrdu, tačno upisano `RESET` i važeću generaciju. Briše ukupni i potrošeni XP i kupovine, vraća nivo 1 i početni izgled, a čuva slova, odgovore, misije, opremu i borbe. Stari formulari i ponovljeni reset odbijaju se posle promene generacije. Stara rezerva opreme može da vrati delove, ali ne i plaćenu boju čija je kupovina obrisana. Već započeta borba zadržava raniji snimak.

## Automatske provere

Pun `bin/check` prolazi: **101 Rails test / 2.218 tvrdnji i 10 JavaScript testova geometrije**, bez neuspeha, grešaka ili preskočenih testova. Zapis: `automatske-provere.txt`.

Pre toga prošlo je 49 ciljanih backend i regresionih testova sa 629 tvrdnji na zasebnoj test bazi. Obuhvat uključuje:

- Sve redoslede kupovine, sprečavanje preskakanja i upotrebu ranije kupljenih kasnijih izbora.
- Cene sa servera, dovoljan/nedovoljan budžet, ponovljene i istovremene kupovine.
- Obaveznu potvrdu i tačan tekst reseta, odbijanje stare generacije i odsutne generacije u HTTP formularima.
- Dva istovremena reseta i kupovinu koja se takmiči sa resetom; novo stanje ne nasleđuje staru naplatu.
- Potpuno očuvanje istorije učenja, tekuće misije, opreme i borbi.
- Novi XP iz aktivne misije posle reseta i odsustvo nagrade za ponovljen stari odgovor.
- Vraćanje stare opreme bez ponovnog otključavanja obrisane plaćene boje i rollback neuspešnog čuvanja.

Dodatnih **pet JavaScript provera kontrola** prolazi u `practice-controls.txt`: prazan crtež i tačka ne završavaju slovo, cela reč zahteva sva slova, brisanje jednog čuva ostale crteže, izbor za prazninu ne otkriva odgovor i slanje zaključava kontrole. Ovo su provere stanja kontrola, odvojene od browser provere pointer događaja.

## Production Rails/Rack provera

`production_check.rb` je pokrenut nad novom `storage/v5-production.sqlite3`, uz svih šest migracija i uključenu CSRF zaštitu. Zapis `production-provera.txt` završava sa **PRODUCTION SMOKE: PASS**.

Provereno je svih 17 izbora, redosled kupovine i povratak u odgovarajuću kategoriju. Direktna kupovina robo-dinosaurusa odbija se dok nedostaju prethodni dinosaurusi. Kupovine redom ostavljaju ukupno zarađeni XP nepromenjenim.

Pravi HTTP zahtev za reset sa pogrešnom potvrdom ne menja stanje; ispravan zahtev briše XP i kupovine, podiže generaciju i vraća početne izbore. Sve vrednosti istorije učenja, aktivne misije i borbe ostaju sačuvane. Stari odgovor ne daje ponovnu nagradu, sledeći zadatak daje 10 XP, a ponovljeni stari reset ne briše taj novi XP. Stara oprema vraća se uz zelenu boju umesto obrisane kupovne lave. Istorijska borba ostaje robo-dinosaur sa lavom.

Posle dodavanja sintetičkog budžeta provereno je da stara kupovna forma i dalje biva odbijena iako novca ima dovoljno, kao i stara forma za izbor izgleda i zahtev bez generacije. Nova generacija normalno kupuje. GET prodavnice, roditeljskog pregleda, slovarice i arene vraćaju 200.

Probni XP i rezultati crtanja su sintetički podaci ove provere. Glavna i zajednička test baza nisu otvarane; SHA-256 otisci pre i posle su isti. Nije pokrenut HTTP server ni browser. Ova provera potvrđuje Rails/Rack tok, a ne dodir, HTTPS, reverse proxy ili javni hosting.

Posle dorade keširanja posebno je provereno svih 17 jedinstvenih CSS/JS adresa iz production prikaza, uključujući osam modula import mape. Svaki otisak odgovara sadržaju fajla i svaki GET vraća 200. Zapis: `static-assets-production.txt`. To je naknadna provera samo čitanjem nad postojećom izdvojenom QA bazom; kupovine i reset nisu ponavljani.

## Browser i probni reset

Početnih probnih 1.160 XP kupovinom triceratopsa smanjuje se na 920; stegosaurus postaje dostupan. Posle kupovine stegosaurusa ostaje 500 XP i za robo-dinosaurusa nedostaje 100. Filtriranje kategorija i prikaz sveta pregledani su na desktopu i širini 320 px.

Na roditeljskom pregledu prazan formular sprečava reset izvornom validacijom browsera i 500 raspoloživih XP ostaje sačuvano. **Uspešan destruktivni reset nije potvrđivan klikom u browseru.** Potvrđen je stvarnim HTTP zahtevom kroz production Rails/Rack proveru iznad. Browser probna baza resetovana je zasebnom zaštićenom Rails skriptom radi provere narednog zadatka.

`reset-fixture-result.txt` beleži prelazak ukupnih 1.160 i potrošenih 660 XP na 0, generaciju 2 i početne izbore. Pre i posle reseta sačuvani su isti brojevi:

| Podatak | Pre i posle |
| --- | ---: |
| Završene misije | 8 |
| Pokušaji | 96 |
| Zapisi o slovima | 11 |
| Osvojeni delovi | 8 |
| Sesije | 9 |
| Borbe | 1 |

Tekuća sesija 9 ostala je dostupna. Posle reseta u stvarnom browseru ispisano je И sa rezultatom 100; donelo je novih 10 raspoloživih XP.

Zatim je kroz interfejs rukom ispisana cela reč САТ. Posle prvog završenog slova provera reči ostaje nedostupna. Brisanje А čuva ranije završeno С. Tek posle sva tri završena slova dostupno je slanje; tačan odgovor prikazuje sliku sata i značenje reči i podiže saldo na 20 XP.

Čitanje КОЗА uz izbor slike, pamćenje skrivene reči миш i dopuna КОЗА uz izbor i crtanje К i А uspešno su završeni u browseru. Saldo raste redom na 30, 40 i 50 XP. Namerno pogrešan izbor „кит” u rečenici prikazuje obavezno kratko ponavljanje, povećava broj koraka na 13 i ostavlja 50 XP.

To je **pet stvarno odigranih tačnih zadataka i jedan pogrešan odgovor** u ovoj v5 misiji. Preostali koraci završeni su zaštićenom `qa/v5/prepare.rb` skriptom sa `QA_MISSIONS=9`, da bi se pregledao završni ekran. Konačni prikaz ima 145 XP za ovu misiju i deveti deo; zapis je `mission-fixture-finish.txt`. Cela misija v5 nije ručno odigrana od početka do kraja; ranija cela browser misija v3 ostaje zaseban dokaz.

Slovarica je pregledana sa malim slovima: pretraga „авион” daje jednu karticu, „ззз” prazno stanje, a uklanjanje pretrage vraća svih 30 kartica. U areni je odigran potez: ostaje sedam delova oklopa i prikazana je druga runda. Na završnom prikazu kategorije boja ostaju vidljivi naziv i navigacija; širina dokumenta je 305 px na ekranu od 320 px, bez horizontalnog prelivanja.

Tokom browser provere otkriveno je mešanje novih ekrana sa starim keširanim CSS-om i modulom za crtanje. Adrese CSS/JS fajlova sada sadrže otisak sadržaja, a browser import mapa obuhvata zavisne module. Nove adrese i raspored koraka potvrđeni su u browseru; potom je uspešno ispisano slovo. Nije uveden build proces ili nova biblioteka.

Snimci proveravanih ekrana:

- `shop-path-desktop.jpg` — redosled dinosaurusa.
- `shop-worlds-320.jpg` — kategorija svetova na uskom ekranu.
- `purchase-confirm-320.jpg` — potvrda kupovine na uskom ekranu.
- `parent-reset-320.jpg` — izdvojene roditeljske kontrole.
- `alphabet-search-320.jpg` — pretraga slovarice.
- `workshop-320.jpg`, `battle-320.jpg` — radionica i arena.
- `trace-empty-320.jpg`, `trace-success-320.jpg` — prazan i uspešno ispisan zadatak.
- `word-meaning-320.jpg` — završena rukom ispisana reč i njeno značenje.
- `recovery-320.jpg` — poruka posle namerne greške i obavezno ponavljanje.
- `mission-reward-320.jpg` — nagrada posle završetka preostalih koraka zaštićenom QA skriptom.

## Ograničenja

Nisu provereni fizički Android, iPhone ni olovka. Uski Chromium prikaz nije potvrda stvarnog mobilnog browsera. Nisu provereni Docker build, javno objavljivanje, HTTPS i reverse proxy, duži prekid mobilne veze niti offline sinhronizacija.

Pisanje je vođeno i proverava se geometrijski: rezultat ne potvrđuje pravilan školski smer i redosled poteza niti prepoznavanje slobodnog rukopisa. Pamćenje i obrazovni učinak nisu potvrđeni tehničkim testovima. Korisnikov pregled i detetova reakcija ostaju merodavni za prihvatanje igre. Srpski govorni glas zavisi od uređaja; provera pravog izgovora na telefonu ostaje otvorena.

Završni dopunski pregled: posle probnog reseta i završetka misije kupljena je ledena boja (145 → 25 XP). Lava tada postaje sledeća dostupna nagrada, uz poruku da nedostaje 95 XP. Back zadržava 25 XP, izabranu kategoriju i nijedan otvoren dijalog; kupovina nije ponovljena. Snimak potvrde je `purchase-confirm-320.jpg`. Završni desktop snimci su `home-desktop.jpg`, `workshop-desktop.jpg` i `shop-path-final-desktop.jpg`. Tamna pozadina hangara zadržana je i u kupljenim svetovima radi kontrasta svetlih natpisa.

Glavna aplikacija na portu 3000 proverena je samo čitanjem: novi redosled kupovine, verzionisani CSS fajlovi, roditeljska potvrda sa obaveznim RESET tekstom i postojeći novčanik od 1.110 XP. Nema zabeleženih grešaka u konzoli na tom završnom pregledu. `main-shop-desktop.jpg` je stvarni prikaz glavne prodavnice, bez obavljene kupovine. Probni server je zatim zaustavljen; glavni pregled je ostao otvoren na početnoj strani.
