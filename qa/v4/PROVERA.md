# Provera verzije v4 — XP prodavnica, 2026-10-11

## Automatske provere

Pun `bin/check` prolazi: 88 Rails testova, 1.974 tvrdnje i 10 JavaScript testova geometrije; 0 neuspeha, grešaka i preskočenih testova. Rails eager-load takođe prolazi. Zapis: [automatske-provere.txt](automatske-provere.txt).

Završni ciljani shop controller prolaz: tri testa, 48 tvrdnji, bez neuspeha i grešaka; zapis je [shop-final-test.txt](shop-final-test.txt). Provera sintakse prolazi za pet JavaScript modula: `shop.js`, `fx.js`, `application.js`, `workshop.js` i `battle.js`.

Provere prodavnice potvrđuju cene sa servera, nedovoljan i tačan budžet, odvojeni ukupni i raspoloživi XP, besplatno ponovno biranje kupljenih izgleda, zaštitu od duple kupovine i prekoračenja budžeta pri istovremenim zahtevima. Neuspešno čuvanje vraća i naplatu i zapis kupovine. Reset čuva kupovine i potrošnju; novi tačan zadatak dopunjava ukupan i raspoloživi XP, a ponovljen odgovor ne vraća već potrošeni XP. Kupovine ne daju dodatne živote u areni. Vrsta dinosaurusa i boja započete borbe ostaju sačuvane posle promene izabranog izgleda.

Pravila misija ostaju v3: detalji prethodnog browser prolaska kroz sve zadatke nalaze se u [v3 izveštaju](../v3/PROVERA.md). Novi pun skup testova uključuje i te regresione provere.

## Production Rails/Rack provera

Provera prolazi u `RAILS_ENV=production` sa novom, izdvojenom `storage/v4-production.sqlite3`. Svih pet migracija primenjeno je na praznu bazu. Prodavnica vraća 200 i ima 17 kartica. Kupovni POST i izbor izgleda koriste validan CSRF token. Otključavanje se prikazuje na prvom GET zahtevu posle kupovine; sledeći GET ga ne ponavlja. Besplatan izbor početnog i već kupljenog dinosaurusa ne naplaćuje ponovo.

Početnih 600 XP postavljeno je direktno kao probni skup. Kupovina triceratopsa za 240 XP i svemira za 220 XP ostavlja ukupnih 600 XP i nivo 7, sa potrošenih 460 i raspoloživih 140 XP. Početna strana, radionica i slovarica vraćaju 200; izabrana tema i vrsta ostaju vidljive. Provereni su zaglavlje sa raspoloživim XP i svih 30 slova. Novi FX, shop i theme CSS/JS fajlovi vraćaju 200 sa odgovarajućim tipom sadržaja. Zapis: [production-provera.txt](production-provera.txt).

Glavna i test baza nisu otvarane kao SQLite veza u ovoj proveri; njihovi SHA-256 otisci ostali su isti. Tajni ključ je generisan samo u memoriji i nije ispisan ili sačuvan. Ovo je Rails/Rack integration provera bez HTTP servera i browsera; ne potvrđuje animacije, dodir, zvuk, HTTPS, reverse proxy, kontejnere niti javni hosting.

## Pregled dinosaurusa

Pregledano je 15 SVG prikaza: četiri vrste sa 0, 8 i 16 delova opreme i robo-dino u tri nove palete. Svi prolaze proveru SVG strukture i vizuelni pregled. Pregledi su u [vrste](../shop-species/species-overview.png), [oprema](../shop-species/equipment-overview.png) i [palete](../shop-species/palette-overview.png).

## Browser provera

Provera je izvedena u stvarnom ugrađenom Chromiumu na izdvojenoj `storage/v4-browser.sqlite3`. Početak je pripremljen probnim podacima: jedna završena misija i 145 XP. Otkazivanje dijaloga kupovine ostavlja 145 XP. Kupovina ledene boje za 120 XP ostavlja 25 raspoloživih XP; osvežavanje zadržava vlasništvo i ne ponavlja prikaz otključavanja. Jedno slovo je stvarno ispisano u browseru, sa rezultatom 100: dobijeno je 10 XP, odnosno 155 ukupnih i 35 raspoloživih XP.

Zatim je `qa/v4/prepare.rb` dopunio isključivo probnu bazu na osam misija, osam delova i 1.160 ukupnih XP. Preostalih 1.040 XP korišćeno je za sledeće kupovine u browseru:

| Kupovina | Cena | Raspoloživo posle kupovine |
| --- | --- | --- |
| Triceratops | 240 XP | 800 XP |
| Svemir | 220 XP | 580 XP |
| Komete | 220 XP | 360 XP |
| Okean | 220 XP | 140 XP |

Ovde nije ručno odigrano osam celih misija; pripremljeni podaci služe pregledu kupovine i opreme. Ukupni XP se kupovinom ne smanjuje. Ponovno biranje reksa, kupljenog triceratopsa i svemira ostavlja 140 XP. Back i osvežavanje ne stvaraju novu naplatu; posle dorade povratka kroz browser cache i beleženja već viđenog otključavanja ne ponavljaju ni taj dijalog. Konkretno, posle kupovine okeana i povratka kroz Back ostalo je 140 XP i nijedan otvoren dijalog.

Pri otključavanju kometa u DOM-u je zabeleženo 28 čestica sa izabranim efektom, a aktiviranje opreme u radionici koristi isti efekat. Radionica i arena prikazuju ledenog triceratopsa sa osam delova: početni životi su 11 prema 9. Jedan stvarni potez u areni skida jedan deo; novi SVG zadržava triceratopsa.

Pregledani su desktop 1280 px i uski prikazi 390 i 320 px. Na 320 px document scrollWidth je 305 px, bez horizontalnog prelivanja. Tokom pregleda popravljeni su mobilna navigacija i prelivanje dijaloga za otključavanje. Nema zabeleženih JavaScript grešaka.

Konačni snimci: [prodavnica na desktopu](shop-desktop.jpg), [prodavnica na 320 px](shop-320.jpg), [otključavanje sveta](world-unlock-320.jpg), [otključavanje kometa](comets-unlock-320.jpg), [efekat tačnog odgovora](answer-burst.jpg), [komete u radionici](workshop-comets-320.jpg) i [triceratops u areni](battle-tricera-320.jpg).

`unlock-desktop.jpg` i `unlock-mobile.jpg` ostaju raniji snimci nastali pre ispravki prelivanja odnosno navigacije. Ne predstavljaju konačni izgled.

## Arhiva i granice

Pre promene sačuvani su `revisions/2026-10-11-141839-v3/source.tar.gz` i konzistentan SQLite backup `development.sqlite3` u istom folderu. Izgled i kupovine su odvojeni od postojeće istorije učenja. Plaća se osvojenim XP, bez pravog novca.

Pri završnom čitanju glavna baza i taj backup imaju 1.110 ukupnih XP, osam završenih misija, peach boju i generaciju sklopa 2. Glavna baza ima početne shop vrednosti: potrošeno 0 XP, reks, livada i zvezdice. Stvarni XP nije trošen za QA kupovine. Ovo je snimak pri čitanju, a ne tvrdnja da se napredak neće promeniti kasnijim korišćenjem.

Nisu provereni fizički Android, iPhone ni olovka, Docker build ili javni hosting. Vođeno pisanje i dalje koristi geometrijsku procenu; ne proverava školski smer/redosled poteza i ne prepoznaje slobodan rukopis. Govorni izgovor zavisi od srpskog glasa na uređaju. Tehničke provere ne dokazuju detetovu motivaciju niti dugoročno pamćenje.
