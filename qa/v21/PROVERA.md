# V21 — Dino-vožnja i više školskog sadržaja

Datum: 2026-10-13. Lokalna verzija, bez objave i novih servisa.

## Ponašanje

- Posle šest originalnih zadataka u oba režima sledi opciona vožnja. Recovery zadaci ne pomeraju polovinu. Vožnja ne menja cursor, XP ili napredak slova.
- Tri trake, tri srca, 24 sekunde, 11 kamenova u razmacima od 1,8 s i dve slobodne trake. Kamen se najavljuje prilaskom 2,1 s pre sudara. Treći sudar završava vožnju. Tastatura, velika dugmad, prevlačenje i dodir trake pomeraju za jednu traku.
- Pobeda daje jedan štit za arenu iste misije. Prvi protivnikov pogodak troši njega, sledeći može da potroši posebno aktivirani svetlosni štit, pa tek zatim oklop/srca. Mrgudovi životi se zbog bonusa ne povećavaju. Osvežavanje, dupli zahtev, ponovljeni start i preskakanje posle pobede ne umnožavaju ili brišu nagradu.
- Preskakanje ili poraz nastavljaju čitanje. Nema ponavljanja iste završene vožnje radi nagrade. Napredak vožnje u istom tabu privremeno je u `sessionStorage`; rezultat i štit su u SQLite. Bez tog privremenog zapisa može se krenuti od početka iste još aktivne staze. Ovo nije režim rada bez servera.

## Sadržaj

543 reči, 490 sa najviše pet slova; 267 slikovnih pojmova i 30 lokalnih SVG crteža. Dodato je 120 reči i 22 crteža. Skup do Е ima 75 reči i 24 slike. Nove ilustracije vizuelno su pregledane zajedno; orah/panj i ostali konkretni pojmovi imaju prepoznatljiv predmet umesto približnog emoji-ja.

95 novih kratkih prostornih rečenica koristi samo dozvoljena slova u stvarnom obliku reči: npr. „столу”, „ранцу”, „кутије”. Četiri slike imaju isti predmet i isti oslonac; razlikuje se položaj. Od У dolazi jedan prostorni zadatak u misiji. Relacije se smenjuju u prvih pet prostornih misija; do Е ostaje osam rečenica osobe/predmeta. Uklonjene su samo duže stare prostorne rečenice iz školske rotacije; režim cele azbuke ostaje isti. [Brojevi po skupu i probna nedelja](content-audit.json).

## Provere

`RAILS_ENV=test TEST_DATABASE_PATH=storage/v21-test.sqlite3 bin/check`: **289 Rails testova / 93.331 tvrdnja**, **35 JS testova**, uspešan Zeitwerk. [Izlaz](check.txt).

Testovi pokrivaju oba režima, stvarnih šest odgovora, recovery, start/skip/finish, pogrešan token, nevažeće poteze/trajanje, završavanje prerano, tuđi browser, duple zahteve, istovremene zahteve iz dva taba i trku sa potpunim restartom. Provereni su štit u areni, nezavisnost redovnog štita, nova arena bez starog bonusa i reset samo jednog browsera. Nezavisno poređenje 1.000 validnih istorija poteza daje isti broj sudara i vreme završetka u Ruby-ju i JS-u.

Sadržaj prolazi sve prefikse/pojedinačna slova i provere slikovnih izbora. [Postojeći audit program](../v20/content_audit.rb) ponovo je odigrao 42 stvarne školske misije na izdvojenoj test bazi: 48 različitih ciljanih reči, osam rečenica, 42 različite kombinacije i 504 zadatka (420 čitalačkih / 84 pisaća), 42 nagrade, 6.090 XP. To proverava širinu i računanje, ne obrazovni učinak ili trajanje detetovog interesovanja.

## Browser

Izdvojeni `localhost:3002` i `storage/v21-browser.sqlite3`; bez probnih poteza u korisničkoj bazi. Stvarna vožnja proverena na 320/390 px i 1280 px: pobeda kroz dugmad sa jednim sudarom, poraz bez pomeranja, tastatura, pauza, osvežavanje/nastavak, finalni sačuvani broj srca, preskakanje i povratak na sedmi zadatak. Nema horizontalnog prelivanja ni zabeleženih JS grešaka. Dekorativni slojevi ne pomeraju put kada se fokusira dugme. Zvuk/efekti koriste postojeće mute i reduced-motion postavke.

[Mobilna vožnja](drive-mobile-320.jpg), [osvojen štit](drive-victory-mobile.jpg), [desktop](drive-desktop.jpg). Fizički iPhone/Android nisu proveravani; pregled je bio browser sa mobilnom širinom. Swipe rukom na telefonu nije potvrđen.

Zasebno proverena školska rečenica [„Лопта иза стола” na 320 px](spatial-mobile.jpg): četiri jasno različita položaja, jednaka širina ekrana i dokumenta (320 px), tačna slika prihvaćena sa +10 XP i prelaskom 10→11. [Prihvaćen odgovor](spatial-correct-mobile.jpg). Nema JS upozorenja/grešaka. Probni tab zatvoren, mobilna širina vraćena.

## Podaci i povratak

Tag `v20-stable-before-dino-drive` čuva kod pre izmene. Konzistentne lokalne kopije su u ignorisanom `revisions/2026-10-13-v20-before-drive/`, uključujući svežu `before-local-migration.sqlite3`. Nova migracija dodaje samo `road_runs`, povezanu sa misijom jedinstvenim stranim ključem. [Poređenje](migration-check.json) potvrđuje svih osam ranijih tabela i sve vrednosti bez promena; SQLite integritet je ispravan. Glavna aplikacija pokrenuta je na `127.0.0.1:3001`.

Za vraćanje koristiti zajedno stari kod i odgovarajuću rezervnu bazu uz zaustavljen server, nakon čuvanja sadašnje baze. GitHub `main` i Railway ostaju prethodno objavljena v19. Nema dodatnih zavisnosti ni plaćenih slika/zvuka/servisa.
