# Ћирило — stanje projekta

Aktuelno: 2026-10-14, **v26 je javno objavljena na Railwayu**, commit `7f5439a`, deployment `629b43f4-7e51-41a2-8529-024ef0505740`, status **SUCCESS**. Nova muzika: „Bouncy Toy Time” za vožnju i „Мргуд, Страшни Мргуд” za arenu. GitHub provere i javna provera oba MP3 fajla, skripti i sačuvane misije prolaze. Trial resursi su isti. Lokalni server ostaje na `127.0.0.1:3001`. Podrazumevani školski režim do Е i roditeljski izbor naučenih slova ostaju; cela azbuka je zasebna opcija. Zvučni vodič je odložen. Ovaj folder sadrži Rails aplikaciju za učenje srpske ćirilice; ne sadrži prezentacije niti prethodni kurs. Stariji odeljci opisuju tadašnje stanje.

## V26 — nova muzika igara (objavljeno, 2026-10-14)

Vožnja koristi korisnikovu „Bouncy Toy Time”, arena „Мргуд, Страшни Мргуд” (naknadni korisnikov izbor, URL verzija 2). Lokalni MP3 fajlovi imaju ukupno 1,43 MB, bez omota i dodatnih metapodataka, sa ujednačenom glasnoćom. Izvorni fajlovi nisu menjani. Novi buffer loop zamenjuje sintetizovanu melodiju; efekti i prethodna Android aktivacija ostaju. Muzika se nastavlja sa iste pozicije posle pauze/utišavanja. Zakašnjelo učitavanje ne oživljava završenu igru; izlazak prekida preuzimanje i oslobađa audio.

Prolazi 23 audio testa i svih sedam JS test datoteka, plus 10 Rails testova identiteta uređaja. HTTP potvrđuje oba MP3 snimka; stvarni browser proverava vožnju, potez arene i kontrole zvuka bez JS grešaka. Fizički telefon i slušni kvalitet nisu provereni. Nema migracija ni izmene lokalne glavne baze. GitHub potvrđuje kompletne Rails/JS, production i Docker provere za objavljeni commit; javni pregled potvrđuje oba MP3 snimka i isti sačuvani napredak. [Dokazi](qa/v26/PROVERA.md).

## V25 — proširenje reči i čitanja (objavljeno)

- Školska banka 543→781 reč/oblik; 710 do pet slova. Do Е: 75→120 reči, 24→37 slikovnih odgovora. Pet novih slikovnih pojmova ili ranije tekstualnih pojmova, osam slikovnih množina. САТИ, АТОМ i БРАВА ostaju tekstualni zbog nejasnog predstavljanja slikom.
- Dvadeset novih lokalnih SVG ilustracija; ukupno 50. Slike množina prikazuju više predmeta i dele grupu značenja sa jedninom. Nova reč БОР je u grupi stabala; slični crteži ne nude se kao različiti tačni odgovori.
- Cela azbuka: 112→160 reči, svaka nova sa kratkom dopunom rečenice; lokalne ilustracije prolaze kroz sve odgovarajuće zadatke i prikaz značenja posle odgovora.
- Školske priče do Е: 8→20. Rečenice u istoj misiji menjaju i osobu i predmet. Kasnije škole imaju 160 rečenica o osobi/predmetu, ukupno 267 sa ostalim vrstama priča.
- Planer koristi poslednjih šest školskih misija, prati sve reči iz spajanja i daje sličnije distraktore za sliku→reč. U 42 simulirane misije: 66 ciljnih reči, svih 37 slikovnih odgovora i svih 20 rečenica do Е; bez ponovljenih ciljnih reči unutar misije. Sva pitanja ostaju u izabranim slovima.
- Nema migracije. Započete misije, napredak, XP i identiteti browsera ostaju. Provere koriste izdvojene test i browser baze; stvarna baza nije menjana. Detalji: [qa/v25/PROVERA.md](qa/v25/PROVERA.md). GitHub CI, Docker sa trajnom bazom i javni read-only pregled prolaze: ista prethodna probna misija/zadatak/napredak i svih 20 novih SVG identični lokalnim fajlovima. Servis, disk i trial limiti ostali su isti.

## Android zvuk u igrama — v24

Korisnik je prijavio da u Android Chrome-u čuje efekat uspešnog zadatka, ali ništa u vožnji/areni. Audio modul je reagovao samo na pointerdown i mogao je zauvek da ostane u čekanju prvog blokiranog resume zahteva. Sada touch/pen pokreće zvuk na puštanje, postoje touchend/click rezervne putanje, a nov stvarni gest ili uključivanje zvuka mogu ponoviti zaglavljeni zahtev. FX zadataka i glasnoća nisu menjani.

Četiri nova regresiona scenarija padaju na starom kodu, a prolaze na ispravci; svih 17 audio i ukupno 62 JS testa prolaze. GitHub dodatno potvrđuje 298 Rails testova / 93.412 tvrdnji i Docker provere. Deployment `41580f93-5a61-42ba-bb55-af1857a8000e` za `349d1de` je SUCCESS; javna provera potvrđuje tačan novi audio fajl i nastavak stare misije. Nema migracija ili promene resursa. Korisnikova provera na fizičkom Androidu još nije potvrđena. [Dokazi](qa/v24/PROVERA.md).

## Objava školskog režima i igara — v23

Na izričit zahtev korisnika, `school-learning` je spojena bez konflikata u `main` i objavljena preko postojećeg GitHub izvora. Deployment `9a85c6fb-c07d-4cfb-b879-48193ee37849` za commit `11ebe3bbf890ddf9b9d5c2f8b5058d882032c4c9` ima status **SUCCESS**. Isti servis, isti volume od 500 MB, jedna replika, 0,5 vCPU / 500 MB i uključeno uspavljivanje; nema novih servisa, promene plana ili ključa.

Dodate su samo dve ranije pripremljene migracije v20/v21. Pre njih novi startup hook pravi i proverava samostalnu SQLite rezervu na istom volume-u. Log potvrđuje rezervu pre verzije `20261013000200`. SSH nije konfigurisan; novi ključevi nisu dodavani. Snimak na istom disku nije zaštita od gubitka tog diska.

GitHub za objavljeni commit potvrđuje **298 Rails testova / 93.412 tvrdnji, 58 JS testova**, production proxy/kolačiće i Docker sa trajnom bazom. Javni pregled vraća istu staru probnu misiju i zadatak sa samo stalnim cookie-jem, potvrđuje tačan sadržaj četiri promenjene skripte i školske opcije do Е. Browser početna radi bez JS grešaka/upozorenja. [Dokazi, rollback i granice](qa/v23/PROVERA.md).

## Muzika, putanja i naočare — v22

Vožnja i arena koriste zasebne lokalno sintetizovane melodije i efekte: skretanje/sudar, pogodak/promašaj/štit/nerešeno/moć, fanfara sa aplauzom i zvuk poraza. Jedno postojeće dugme utišava sve, uključujući druge otvorene tabove. Zvuk čeka stvaran dodir/taster; pauza, skriven tab i izlazak prekidaju muziku. Browser Back obnavlja zvuk samo za aktivnu igru; vožnja ostaje pauzirana. Nema novih fajlova sa snimcima, servisa ili troška.

Autić na putanji prati stvarni položaj šestog originalnog zadatka čak i uz dodatna ponavljanja, a posle uspeha dobija mali štit. Naočare sada imaju veliki fokusiran prikaz sledećeg poteza, oblačić iznad Mrguda i status „Потез откривен”. Čuvanje protivnikovog poteza već je radilo; potvrđeno je u testovima i browseru. Popravljen je gubitak oblačića posle neuspelog zahteva.

Prošlo je 293 Rails testa / 93.383 tvrdnje i 58 JavaScript testova. Browser provera na 320 px obuhvatila je autić bez horizontalnog prelivanja, otkrivanje i stvarno odigravanje istog poteza, pobedu/poraz arene, skretanje/sudare, pauzu/nastavak i mute kontrole. Nisu slušno provereni zvučnici niti fizički Android/iPhone. [Dokazi i granice](qa/v22/PROVERA.md).

Tačka povratka: tag `v21-stable-before-game-audio` na `acdc013`, baza u `revisions/2026-10-13-v21-before-game-audio/`. Nema migracije; testovi su koristili zasebne baze. Rad ostaje na grani `school-learning`, bez objave na GitHub/Railway.

## Dino-vožnja i više kratkog čitanja — v21

Oba režima nude kratku vožnju nakon šest originalnih zadataka. Mrgud baca kamenje na tri trake; dete ima tri srca, 24 sekunde do cilja, dugmad/tastaturu/dodir/prevlačenje, pauzu i preskakanje. Osvojeni štit automatski čuva jedan pogodak u areni iste misije, pre redovnih moći/opreme. SQLite čuva jednu vožnju po misiji; server proverava trajanje i poteze, sam računa sudare i ne prima tvrdnju klijenta o pobedi. Privremeni tok vožnje u istom tabu koristi `sessionStorage`; osvojeni bonus je u bazi. Potpuni restart briše i ovu tabelu. XP i dvanaest obrazovnih koraka ostaju isti.

Banka je proširena na 543 reči (+120), uz 22 nova SVG crteža, ukupno 30. Do Е sada ima 75 reči i 24 slikovna pojma. Dodato je 95 kratkih prostornih rečenica sa tačnim padežima. Od У, čim izabrana slova dopuštaju, jedan zadatak po misiji vežba odnos predmeta i auta/stola/kutije/ranca; drugi ostaje razumevanje rečenice. Nove relacije se ne gube iza duge rotacije starih pitanja. Broj školskih priča na celom skupu je 187. Puna azbuka čuva svoj raniji planer i dobija istu vožnju.

Prošlo je 289 Rails testova / 93.331 tvrdnja i 35 JS testova, plus 1.000 poređenja obračuna vožnje između Ruby-ja i JavaScript-a. Test nedelja od 42 školske misije kroz Е daje 48 različitih ciljnih reči, osam rečenica, 504 zadatka i uobičajenih 6.090 XP. Browser potvrđuje stvarnu pobedu, poraz, pauzu/nastavak, refresh, preskakanje i prikaze 320/390/1280 px. [Dokazi i granice](qa/v21/PROVERA.md).

Tačka povratka: tag `v20-stable-before-dino-drive` na `f7d36d9`; baza u `revisions/2026-10-13-v20-before-drive/`. Glavna lokalna baza migrirana je bez izmene ijednog postojećeg reda. Rad ostaje na grani `school-learning`; GitHub/Railway nisu menjani.

## Školska slova — v20

Roditelj u „Šta vežbamo?” bira školska slova ili celu azbuku, poslednje slovo po bukvaru ili proizvoljan podskup. Tačan redosled je А М И Т О Н С Е Р Ј У Ш Л Љ З В Г П К Д Б Њ Х Ж Ч Ћ Ф Ц Џ Ђ; podrazumevano je prvih osam, do Е. Školska igra ne uvodi slova automatski. Čitav sadržaj zadatka, uključujući pogrešne ponuđene odgovore i ponavljanje posle greške, ostaje unutar izbora. Uputstva interfejsa nisu ograničena.

Nova školska banka ima 423 reči od 2–6 slova, 388 do pet slova. Do Е je dostupno 67 reči, 18 ilustrovanih pojmova i osam rečenica sa osobom i predmetom. Osam novih SVG crteža uklanja nejasne emoji i širi početnu ponudu. Imena/glagoli bez odgovarajuće slike koriste se za pamćenje. Za kasnije skupove postojeće prostorne priče ulaze tek kada su sva slova njihovih rečenica poznata. Stara banka od 112 reči i kompletna igra cele azbuke sačuvane su.

Odigrana test nedelja od 42 misije daje 44 različite ciljane reči, osam rečenica, 504 zadatka (420 čitanja / 84 pisanja), 42 nagrade i 6.090 XP. Različite kombinacije uz namerno ponavljanje reči podržavaju vežbanje; to nije obavezan dnevni broj igara. Na najmanjim skupovima izbor je prirodno uži.

Promena režima/slova važi od sledeće misije; aktivna čuva svoja pitanja i snimljen skup slova. Nagrade i napredak zajednički su, bez novih profila. Potpuni restart čuva roditeljska podešavanja. Prošlo je 264 Rails testa / 75.007 tvrdnji, 29 JS testova, provera svih prefiksa i pojedinačnih slova i zaseban pregled svih parova slova. Roditeljska forma, izbor slike, greška/ponavljanje, nova rečenica i SVG značenje provereni su u browseru na 320 px. [Dokazi i granice](qa/v20/PROVERA.md).

Kod pre promene čuva tag `v19-stable-before-school-mode`; rad je na grani `school-learning`. Baza je rezervisana u `revisions/2026-10-13-v19-before-school-mode/`. Migracija i na kopiji i na glavnoj lokalnoj bazi čuva sve stare redove i vrednosti. Stare misije ostaju u režimu cele azbuke. Railway i GitHub nisu menjani u ovoj iteraciji.

## Javna objava na trial nalogu — v19

Korisnik je omogućio Railway CLI, tražio štedljivo korišćenje trial naloga i izričito zatražio javni GitHub repozitorijum. [mradenkovic-raf/cirilo](https://github.com/mradenkovic-raf/cirilo) sada ima potvrđenu vidljivost `PUBLIC`. Istorija ne sadrži lokalne baze, `.env.railway` ili Rails ključeve. Lokalni napredak nije kopiran na server niti menjan u proverama.

Jedan projekat, jedno production okruženje, jedan servis i jedan volume od 500 MB u Holandiji. Servis ima jednu repliku, limit 0,5 vCPU / 500 MB i uključeno uspavljivanje. Puma radi kao jedan proces sa tri niti. Nema novih baza/worker-a, promene plana, doplate ili uključivanja backup servisa. Trial status je potvrđen; novčani limit nije proizvoljno postavljan. Podaci o nalogu i obračunu ne objavljuju se u javnom repozitorijumu.

Railway prvo nije mogao da pristupi privatnom repozitorijumu. Posle promene vidljivosti povezan je javni GitHub izvor `main`; ta objava (`a28039c8-0238-4305-9498-8c95ea1f7d2b`, kod `614aff2`) završila je sa `SUCCESS`. Raniji dupli CLI build otkazan je pre objave. HTTPS, CSS/JS, stalni zaštićen cookie, stvarna CSRF zaštita, odvojeni browseri i ista sačuvana misija posle kontrolisanog restarta provereni su na javnom servisu. Početna je otvorena u stvarnom browseru bez zabeleženih JS upozorenja ili grešaka. Za proveru su napravljena dva zasebna HTTP identiteta i jedna probna misija; nisu korišćeni tuđi kolačići.

Javni GitHub izvor je povezan, ali automatski deployment trigger nije napravljen: objave su zasad ručne preko CLI-ja. GitHub workflow `Check` ostaje. Trial uspavljivanje je podešeno, ali ceo ciklus uspavljivanja/buđenja i fizički telefoni nisu provereni. [Podešavanja i postupak](RAILWAY.md), [dokazi i granice](qa/v19/PROVERA.md). Stariji odeljci ispod opisuju istorijsko stanje.

## Priprema za Railway — v18

Korisnik je odobrio pripremu objave. Privatni repo je [mradenkovic-raf/cirilo](https://github.com/mradenkovic-raf/cirilo); privatnost je potvrđena GitHub API-jem. Najnoviji kod je na `main`, povezanom sa `origin/main`; stare verzije ostaju u istoriji i tagovima. Prvi deploy i javni Railway servis još nisu napravljeni.

Docker sada priprema vlasništvo novog volume-a i pokreće migracije/Pumu kao UID 1000. SQLite mora biti unutar Railway volume-a; startup odbija nedostajući disk ili pogrešnu putanju. Migracije ostaju pri runtime startu. Production prihvata konfigurisani javni domen i Railway healthcheck host; `/up` ne preusmerava, ne pravi cookie i ne otvara nov napredak. Privatni ključevi, sve lokalne baze i rezerve isključeni su iz image-a. Pripremljena je lokalna `.env.railway` sa novim trajnim ključem, dozvolama 0600, van Gita i image-a.

Lokalno i na GitHub-u prolazi 225 Rails testova / 14.391 tvrdnja i 29 JavaScript testova. Posebna production provera dva Rails procesa potvrđuje HTTPS/CSRF, odvojene browsere i isti cookie/XP posle restarta. GitHub workflow `Check` uspešno je izgradio Docker image i proverio dva containera sa istim novim volume-om: ista misija ostaje dostupna preko trajnog cookie-ja, Rails PID 1 je UID 1000. [Uspešan run](https://github.com/mradenkovic-raf/cirilo/actions/runs/38285646101) proverava commit `0889b37`; naknadna dopuna sadrži samo dokumentaciju i rezultate. Svih osam tabela glavne baze ostalo je identično rezervi. [Postupak objave](RAILWAY.md), [nalazi](qa/v18/PROVERA.md).

Prethodni kod je na tagu `v17-stable-before-railway` (`9d21b09`), objavljenom i na GitHub-u, a konzistentna lokalna baza u `revisions/2026-10-12-v17-before-railway/`. Priprema je rađena na grani `railway-preparation`; `main` je pomeren unapred bez prepisivanja istorije.

## Gde je predmet — v17

Dodato je 20 rečenica: jabuka ili lopta u, na, pored, ispred ili iza ranca/kutije. U sva četiri odgovora su isti predmet i ista posuda; razlikuje se samo položaj. Uvek su zajedno ponuđeni bliski odnosi u/na, odnosno ispred/iza kada je jedan od njih tačan. Predmet u posudi zaklanja prednja ivica, iza njega bočna ivica, a ispred prekriva prednju stranu; na vrhu se vidi ceo predmet. Nema tekstualnog ili glasovnog otkrivanja odgovora.

Prostorni zadatak dolazi na drugom redovnom koraku, a na jedanaestom ostaje jedna od 12 ranijih priča. Ukupno 32 rečenice i dve priče po misiji; 12 koraka, 145 XP i dva pisanja ostaju. Format novih misija je 7, započete V3–V6 ostaju nepromenjene. Nema migracije ili resetovanja.

Prošlo je **225 Rails testova / 14.391 tvrdnja i 29 JS testova**, uz dodatnu završnu proveru prikaza (3 testa / 566 tvrdnji), eager loading i provere diff-a. Browser na izdvojenoj bazi potvrđuje mobilni prikaz na 320 px, pravilno odbijanje „na” za „u”, čitalačko ponavljanje sa 0 XP i tačan odgovor sa 10 XP. U glavnoj bazi su odgovori, misije, XP i kupovine isti kao pre rada; poređenje je zabeležilo nov izbor jajeta kod jednog učenika dok je glavni server bio dostupan. Taj izbor je ostavljen netaknut. [Provere](qa/v17/PROVERA.md). Prethodni kod je na tagu `v16-stable-before-spatial-reading` (`afc9f87`), a baza u `revisions/2026-10-12-v16-before-spatial-reading/`. Radna grana: `spatial-reading`.

## Čitanje pre pisanja — v16

Korisnik je postavio čitanje i snalaženje sa slovima kao glavni cilj. Nove misije imaju 10 čitalačkih zadataka i dva pisanja: jedno slovo na četvrtom koraku, a na desetom naizmenično celu reč ili dopunu rukom. Sve postojeće vrste čitalačkih igara pojavljuju se u svakoj misiji; pisanje se ne gomila na početku. Svako ciljno slovo vraća se četiri puta, od toga najmanje tri kroz čitanje/slova. Prioritetno slovo ima i samostalno slaganje, pa konkretne zamene slova ostaju praćene.

Posle greške nova misija vraća čitalački zadatak, bez dodatnog crtanja. Najviše tri ponavljanja, bez dodatnog XP-a i bez računanja samostalnog pamćenja, pa povratak na originalni zadatak. Ostaju 12 redovnih koraka, 145 XP i dosadašnje nagrade. Novi format je 6; započete misije V3–V5 čuvaju kompletno stanje i raniji recovery. Novi odnos važi tek od nove misije. Nema migracije ili resetovanja.

Prošlo je **220 Rails testova / 12.930 tvrdnji i 29 JS testova**, eager loading i provera diff-a. Browser na izdvojenoj bazi potvrđuje čitalački početak, čitalačko ponavljanje posle greške sa 0 XP, povratak i 10 XP za redovan zadatak. Glavni server prikazuje nove roditeljske napomene; stvarni napredak nije menjan. [Provere](qa/v16/PROVERA.md). Prethodni kod je na tagu `v15-stable-before-reading-priority` (`b9c1ede`), a baza u `revisions/2026-10-12-v15-before-reading-priority/`. Radna grana: `reading-priority`.

U [ROADMAP.md](ROADMAP.md) su predlozi za naredne igre: slogovi, slične reči, izbor cele rečenice i kratke priče. Nisu još ugrađene; prvi predlog su slogovi sa proverom značenja slike. Audio vodič ostaje odložen.

## Odvojene igre bez prijave — v15

Korisnik je tražio zaseban napredak svakog uređaja pomoću trajnog kolačića i izabrao da svi krenu od nule. Browser dobija nasumičan šifrovan ključ; SQLite čuva njegov digest. Svi kontroleri koriste `current_learner`, a misije, odgovori, mapa, oprema, jaje, kupovine, borbe i sva tri reseta vezani su za tog učenika. Tuđi ID-jevi vraćaju 404. Nema fallback-a na stari zajednički zapis.

Trajni cookie preživljava običnu sesiju; drugi browser, privatni prozor, obrisani kolačići ili drugi hostname znače zasebnu igru. Novi identitet resetuje CSRF/session podatke, a upis bez poznatog ključa vraća 422. Roditeljski tekstovi objašnjavaju opseg reseta; dečji tok nije proširen izborom profila ili dodatnim pitanjima. Za hosting su potrebni HTTPS, trajna baza i stabilan `SECRET_KEY_BASE`.

Pre izmene inicijalizovan je Git: commit `ce45f7f`, tag `v14-stable-before-device-progress`; `main` ostaje na v14, a nove izmene su na `device-progress`. Izvor i konzistentna stara baza su u `revisions/2026-10-12-v14-before-device-progress/`, van Gita. Migracija `20261012000100` uklanja singleton i dodaje jedinstveni digest. Stari učenik ostaje bez ključa i zato nedostupan browserima; stari napredak nije brisan.

Prošlo je **215 Rails testova / 12.809 tvrdnji i 29 JS testova**, uključujući 17 novih testova identiteta, izolacije i CSRF zaštite. Poseban production Rails/Rack pregled sa HTTPS zahtevima i CSRF-om prošao je. Na kopiji i glavnoj bazi potvrđeno je očuvanje svih starih podataka i SQLite integriteta. Glavni server na 3001 je ponovo učitan: browser sada ima novi prazan napredak, bez probnih odgovora ili reseta. Zaseban browser pregled na `localhost:3002` potvrđuje nastavak iste misije posle zatvaranja taba; probni server je zaustavljen. [Dokazi, ograničenja i postupak povratka](qa/v15/PROVERA.md). Git i rezervne kopije ostaju lokalni.

## Potezi i više reči — v14

Pregledano je svih 30 velikih i 30 malih štampanih oblika, a ispravljena su 42 skupa putanja prema bukvarima Nova škola i Vulkan. Početke prate brojevi i strelice smera, uz razmak oznaka kada dva poteza počinju na istom mestu. Razdvojene su neprirodno spojene uspravne linije, popravljeni А/О/Ж/Ђ/ф i drugi oblici; detaljan nalaz i izvori su u [qa/v14/IZVORI-POTEZA.md](qa/v14/IZVORI-POTEZA.md). Ocena crteža ostaje geometrijska.

Banka ima 112 reči umesto 38. Svako slovo ima najmanje tri početne reči; većina četiri, К pet. Sledeće misije rotiraju te primere. Slične slike se ne nude kao suparnički odgovori. Tri reči imaju osam slova; prilagođeni su pisanje i ostali prikazi na telefonu. Započeti zadaci čuvaju svoje reči, IDs i napredak, a u prikazu odmah koriste ispravljene tragove, uključujući ponuđena slova dopune.

Prošlo je 198 Rails testova / 12.317 tvrdnji i 29 JS testova, još pet provera kontrola pisanja, pa završnih 16 testova / 302 tvrdnje za prikaz. Na izdvojenoj bazi u browseru napisano je А sa tri poteza (100%), pregledano osam slova u pisanju, popravci i povezivanju, kao i veliki ponuđeni odgovori na320px. Glavna baza identična je arhivi pre rada, bez migracije ili reseta. [Provere i granice](qa/v14/PROVERA.md). Arhiva: `revisions/2026-10-12-v13-before-strokes-words/`.

## Lakši protivnik — v13

`BattleOpponent` podešava izbor običnog protivničkog poteza prema početnom maksimalnom broju života obe strane. Cilj je približno 75% pobeda u celoj borbi bez posebnih moći, uz 25% nerešenih pojedinačnih razmena. Pomoć ostaje ista kroz borbu; ne bira se unapred pobednik i nema promene težine zbog izgubljenog srca. Oprema koja već prirodno daje više od 75% ne slabi dete. Štit i pravilno korišćene naočare mogu dodatno da povećaju šanse. Već otkriven protivnički potez ostaje nepromenjen, uključujući stare aktivne borbe. HP, XP, nagrade i istorija se ne menjaju; nema migracije.

Prošlo je 192 Rails testa / 6.332 tvrdnje i 26 JS testova. Simulacija 100.000 borbi (0/1/4/8/16 delova, po 20.000) kroz stvarni izbor poteza dala je 74,49–75,66% pobeda. Matematička verovatnoća nezavisno je proverena, kao i ponovljeni zahtevi, dosledne naočare i postojeće moći. Glavna baza identična je arhivi pre rada. Detalji: [qa/v13/PROVERA.md](qa/v13/PROVERA.md). Arhiva: `revisions/2026-10-11-v12-before-easier-arena/`.

## Srca i oklop — v12

Arena prikazuje tri veća crvena srca i pojedinačne ikonice prsnog oklopa za svaki preostali deo. Potrošene ikone ostaju tamne; kada oklopa nema piše „Без оклопа”. Pri pogotku reaguje samo izgubljena ikona, uz oznaku −1 ОКЛОП ili −1 СРЦЕ i konkretnu poruku o gubitku. Početna poruka kratko objašnjava da oklop čuva srca. Pravila borbe, XP i sačuvana kolekcija nisu menjani.

Prošlo je 186 Rails testova / 6.137 tvrdnji i 26 JS testova. Browser na izdvojenoj v12 bazi potvrđuje prvi gubitak oklopa uz tri sačuvana srca, zatim gubitak srca, i prikaz svih 16 delova bez horizontalnog prelivanja na 320 px. [Detalji](qa/v12/PROVERA.md). Arhiva: `revisions/2026-10-11-v11-before-arena-icons/`. Nema migracije; na glavnoj bazi nisu odigrani probni potezi.

## Put do arene i završnice — v11

Slika značenja je uz slova tokom celog pisanja reči, kao i dopune. Put od zadatka do zadatka prikazuje izabranu vrstu, boju i opremu dinosaurusa; Mrgud čeka na kraju. Pozicija prati sačuvan cursor i stvaran broj zadataka, uključujući dodatna ponavljanja. Tačan odgovor pomera dinosaurusa, greška ne daje završen korak. Prikaz se obnavlja iz baze nakon osvežavanja.

Arena ima izraženu pobedničku medalju, zvezdice/konfete i uzlazni džingl; poraz ima drugačiju karticu, štit i kratku silaznu melodiju. Fokus i prikaz prelaze na ishod. Osvežavanje ili dupli odgovor prikazuju rezultat bez ponovnog slavlja. Zvuk je lokalno sintetisan, poštuje utišavanje i pokreće se iz dodira na potez; smanjene animacije se poštuju. Nema novih servisa, migracija ili promene pravila nagrađivanja.

Prošlo je 184 Rails testa / 6.114 tvrdnji, 23 JS testa i pet dodatnih provera pisanja. Browser je proverio sliku uz šest slova, promenu aktivnog slova, 12→13 koraka posle greške, završnu tačku i oba ishoda arene na 320 px, kao i arenu na 1280 px. Probni odgovori i borbe isključivo u `storage/v11-browser.sqlite3`; glavna baza nije korišćena za QA. Poređenje sa arhivom čuva isti XP i sve zapise učenja/borbi/kupovina; tokom rada se u glavnoj bazi promenila samo boja green→blue i timestamp učenika. Detalji: [qa/v11/PROVERA.md](qa/v11/PROVERA.md). Arhiva: `revisions/2026-10-11-v10-before-play-feedback/`.

## Jaje i novi drugar — v10

U dvorištu dete bira jednog od tri drugara: reksića, triceratopsa ili stegosaura. Od tog izbora broje se tri nove završene misije: pukotina, oko koje proviruje, spremno izleganje. Dugme „Izlegni!” pokreće jednokratnu proslavu i otvara izbor imena (1–20 slova). Drugar ostaje u gnezdu ispod scene. Ovo je jedan pratilac, ne nova kolekcija niti zamena za kupljeni izgled glavnog dinosaurusa. Nema dodatnog XP, novih menija, rokova ili gubitka napretka zbog pauze.

Migracija 000900 dodaje `learners.egg_state`. Izbor pamti početni broj misija; izleganje i ime proveravaju identitet jajeta pod zaključavanjem učenika. Ponovljen zahtev ne ponavlja nagradu/proslavu; stari formular posle potpunog restarta ne vraća obrisano jaje. Potpuni restart briše jaje i ime, delimični reseti ih čuvaju. Postojeći podaci su sačuvani; nova kolona je prazna. Arhiva: `revisions/2026-10-11-v9-before-egg/`.

Prošlo je 181 Rails test / 6.047 tvrdnji i 16 JS testova. U browseru na 390/320 px provereni su izbor, faza 2/3, izleganje, unos imena i trajnost posle osvežavanja. Probne tri misije rešene su servisom samo u izdvojenoj bazi. Provere i snimci: [qa/v10/PROVERA.md](qa/v10/PROVERA.md). Glavna baza migrirana je i server ponovo učitan.

## Raznovrsniji zadaci — v9

Dodati su izbor naziva sa slike, samostalno pronalaženje i popravljanje jednog pogrešnog slova, i spajanje tri reči sa slikama. Povezivanje radi običnim dodirima, bez prevlačenja. Izbor može da se promeni i vrati pre zajedničke provere; nema oznake tačnosti pre odgovora servera. Slične stvarne reči imaju prednost među ponuđenim nazivima. Slike АУТО/ЏИП nisu konkurentski odgovori i svi parovi nikada nisu unapred poravnati.

Misija i dalje ima 12 zadataka i 145 XP. Dva praćenja slova, dva pisanja reči, dve dopune rukom, dva pamćenja i jedna priča ostaju; tri preostala mesta smenjuju stare i nove tipove kroz tri misije. Svaka ima bar jednu novu igru. Format 5 čuva aktivne formate 3/4, njihove ID-jeve, odgovore, cursor, XP i sakrivenu memorijsku reč. Novi tipovi dobijaju postojeće ponavljanje posle greške i zaštitu od duplog XP. Parovi ne menjaju ocenu proizvoljno izabranog slova.

Prošlo je 174 Rails testa / 5.900 tvrdnji i 16 JavaScript testova. Browser provera obuhvata sve nove igre na 320 px, popravku šest slova i parove na desktopu, promenu izbora, undo, nagrade i povratak posle greške. Usput je popravljen fokus na „Dalje” posle završenog slanja. Nema migracija niti novih zavisnosti. Detalji i ograničenja: [qa/v9/PROVERA.md](qa/v9/PROVERA.md).

Arhiva je `revisions/2026-10-11-v8-before-task-variety/`. Svih osam tabela glavne baze ostalo je identično: 290 ukupnih XP, 220 potrošenih, 70 raspoloživih i 10 završenih misija. Probni odgovori dati su isključivo na zasebnoj v9 bazi. Glavni server je ponovo učitan i potvrđeni novi CSS/JS fajlovi.

## Dečji fokus — v8

Korisnik je ocenio da ekrani imaju previše stvari i teksta. Početna sada ima jednu scenu i glavno „Igraj/Nastavi”, trenutnog drugara za spasavanje i mali pregled sledeće nagrade. Zajednička navigacija ima tri izbora; dodatne stranice otvaraju se kroz „Još”. Raspoloživi XP prikazuje prodavnica. Roditeljski pregled ostaje dostupan kroz meni i podnožje.

Radionica postaje centralno dvorište sa kratkim lokalnim pozdravima; oprema i izgled su iza native details. Mapa ističe trenutni cilj, dok se četiri sveta otvaraju pojedinačno. Prodavnica prvo pokazuje sledeću nagradu; svi kupljeni i budući izbori, redosled i potvrda kupovine ostaju. Slovarica zadržava svih 30 slova, pretragu i promenu veličine bez dodatne statistike na karticama.

Zadatak ima jedan naslov i radno polje. Kod dopune izbor slova se skloni dok dete piše, „Promeni slovo” ga vraća, a završna provera reči pojavljuje se tek kada su sva slova nacrtana. Fokus prelazi na polje za pisanje umesto na sakriveno dugme. Slika značenja, greške, ponavljanje i nagrade ostaju. Arena ističe tri poteza i samo posedovane moći, a detaljna pravila su sklopljena. Nisu menjani bodovanje, težina, kupovni redosled, podaci ili modeli. Nema migracija niti novih zavisnosti.

Prošlo je 155 Rails testova / 3.177 tvrdnji i 10 geometrijskih testova. Posle sitnih završnih dorada prošlo je 14 pogođenih Rails testova / 259 tvrdnji i pet testova kontrola pisanja. Browser pregled obuhvata širine 320, 390 i 1280 px, stvarno crtanje slova И i cele reči СОВА, dopunu, kupovinu sa probnim XP-om, moć naočara i pobednički potez u areni. Prazna i puna dvorišta proverena su na izdvojenoj bazi, a postojeća dva drugara na glavnoj, bez upisa napretka. Detalji i ograničenja: [qa/v8/PROVERA.md](qa/v8/PROVERA.md).

Pre rada sačuvani su izvor i konzistentna baza u `revisions/2026-10-11-v7-before-child-focus/`. Svih osam tabela glavne baze ostalo je identično arhivi: 290 XP, 220 potrošeno, 70 raspoloživo, 10 misija. Server je ponovo učitan i nova početna otvorena na portu 3000. Probni server 3002 je zaustavljen.

## Dvorište i potpuni restart — v7

Drugari spaseni na 4/8/12/16 misija sada su u pozadini radionice oko Klika. Lisko se igra loptom, Iskra slaže kristale, Žarko gradi kulu, Zvezdan sprema raketu. Svaki ima posebnu animaciju i pozdrav na dodir sa kratkom proslavom, bez XP ili upisa napretka. Smanjeno kretanje i utišavanje se poštuju. Broj i identitet drugara izvode se iz postojećeg `AdventureMap`; nema nove baze ili duplog stanja. Kartica prikazuje ekipu i sledećeg drugara, a stvarni završetak spasavanja ima link do radionice.

Roditeljske opcije sada imaju zaseban potpuni restart: potvrda roditelja i tačno `RESET`, uz proveru obe postojeće generacije. `FullReset` u jednoj transakciji briše sedam grupa zavisnih podataka, resetuje XP, potrošnju, misije i izgled, prazni rezervu prethodne opreme i povećava obe generacije. Mapa i dvorište se vraćaju na 0/16 i 0/4. Učenik i rastući identifikatori se čuvaju, tako da stare misije, borbe, vraćanje opreme i dupli reseti ne mogu vratiti stari napredak. Arena sada zaključava učenika pre borbe, istim redosledom kao misije i restart. Parcijalni reseti ostaju, uz izričitu napomenu da čuvaju mapu i drugare. Nema migracija.

Prošlo je 155 Rails testova / 3.179 tvrdnji i 10 JavaScript testova geometrije, eager loading i syntax provera workshop skripte. Zasebna production HTTP/CSRF provera potvrđuje odbijanje pogrešnog tokena/potvrde, potpuno brisanje, početno učenje i zaštitu od starih zahteva. Proverene su i konkurentne operacije. Browser pregled na 1280 i 320 px pokazuje četiri aktivnosti, sva četiri lična pozdrava, roditeljski formular i prazno dvorište/mapu posle restarta probne baze. Precizan zapis je `qa/v7/PROVERA.md`.

Pre rada sačuvani su izvor i konzistentna baza u `revisions/2026-10-11-v6-before-friends/`. Poređenje potvrđuje da je svih osam tabela glavne baze ostalo nepromenjeno: 290 ukupnih XP, 220 potrošeno, 70 raspoloživo i 10 završenih misija. Dokaz je `qa/v7/main-preservation.json`. Potpuni restart nije izvršen nad stvarnim podacima.

## Ispravka pokrenutog servera — 2026-10-11

Korisnik je prijavio `undefined method 'action_revision'` pri ulasku u arenu iz završene misije 10. Glavna baza je već imala svih osam migracija i tri nova polja; nov Rails proces je ispravno vraćao `Battle.new.action_revision == 0`. Postojeći Puma proces zadržao je staru strukturu baze u memoriji. Ponovo je učitan preko konfigurisanog `tmp_restart` (`touch tmp/restart.txt`). Model i pravila borbe nisu menjani.

Posle toga je u stvarnom browseru otvorena ista završena misija i pritisnuto „Идемо у арену!”. POST je uspešno napravio borbu 4 i otvorio arenu. Borba ostaje na početku: runda 0, revizija 0, prazna istorija poteza, 7/7 života igrača i 6/6 protivnika. Nije odigran nijedan potez. XP ostaje 290, potrošeno 0, završeno 10 misija; ovo je novije korisnikovo stanje od ranije v6 provere. Snimak je `qa/v6/battle-restart-fixed.png`. README sada zahteva ponovno pokretanje postojećeg servera nakon promene strukture baze i proveru pogođene radnje kroz njega.

## Razvoj v6

Korisnik je odložio zvučni vodič zbog povezivanja sa dodatnim servisom i mogućeg troška, a odobrio ostale stavke iz [ROADMAP.md](ROADMAP.md). V6 obuhvata priče za čitanje sa razumevanjem, vežbe prema zabeleženim zamenama slova, mapu i posebne moći opreme. Zajedničke provere su prošle; detalji prethodne v5 osnove ostaju ispod.

Nove misije koriste format zadataka 4. Imaju 12 redovnih zadataka i ukupno 145 XP: dva praćenja slova, dva pisanja cele reči, dve dopune rukom, dva pamćenja, jedno čitanje reči, jedno sastavljanje, jednu dopunu rečenice i jednu priču. Banka od 12 priča kombinuje predmet sa veličinom, mestom ili radnjom. Četiri SVG izbora predstavljaju sve kombinacije dva predmeta i dva uslova, pa prepoznavanje samo predmeta nije dovoljno. Priča proverava razumevanje cele rečenice, ne povećava niti smanjuje nivo pamćenja proizvoljno dodeljenog slova. Postojeći opcioni glas čita samo opšti naslov, nikada rešenje priče. Prva greška i dalje ubacuje kratko ponavljanje bez XP, najviše tri po misiji.

Započete misije formata 3 ostaju neizmenjene, uključujući ID-jeve zadataka, završene odgovore, cursor i sakrivenu memorijsku reč. Nova mešavina zadataka ulazi u sledeću misiju. Nema retroaktivnog izvođenja zabuna iz istorijskih pokušaja.

`LetterConfusion` čuva očekivano i izabrano slovo, broj zabeleženih prvih grešaka, poslednju grešku i nezavisne uspehe. Dokaz je pogrešan izbor pri dopuni ili jedna jasna zamena u sastavljenoj/memorijskoj reči. Loša geometrija, izbor pogrešne slike, pomoć i ponavljanje nisu dokaz zamene. Planer vraća prioritetni par, prikazuje poređenje tokom vođenog pisanja i ubacuje izabrano pogrešno slovo među kasnije alternative. Dva prva tačna odgovora na odgovarajućem sastavljanju/pamćenju u različitim misijama skidaju prioritet; to nije tvrdnja da je trajno naučeno. Roditeljski pregled pokazuje parove. Oba reseta čuvaju ove zapise.

Mapa `/adventure` ima četiri sveta sa po četiri misije: šumu, pećinu, vulkan i svemir. Svaka završena misija otvara jedan korak, a završetak svakog sveta spasava jednog malog dinosaurusa. Broji postojeće završene misije, ne troši XP i ne zavisi od kupljene teme. Starih devet misija znači dva spasena druga i jedan korak kroz vulkan. Posle 16 misija sva četiri druga ostaju spasena, a učenje, oprema i arena mogu da se nastave. Završni ekran stare misije prikazuje njen istorijski korak; ponovno otvaranje ne dodeljuje nagradu.

Na početku borbe zarađene naočare, svetlosni štit i raketne čizmice daju po jednu posebnu upotrebu. Naočare otkrivaju serverom izabrani naredni protivnikov potez, koji se pamti posle osvežavanja. Svetlosni štit se aktivira unapred i zaustavlja prvi dolazeći pogodak; ostaje uključen kroz pobedničke i nerešene poteze. Rakete završavaju jednu rundu izbegavanjem, bez napada i bez promene života na obe strane. Moć ostaje dostupna i kada deo tokom borbe otpadne. Postojeći životi od opreme ostaju; kupovni izgled ne daje moći. Runda i verzija stanja štite od starih i paralelnih zahteva, a ponovljena ista aktivacija ne troši novu upotrebu.

Pre izmena sačuvani su izvor i konzistentan SQLite backup u `revisions/2026-10-11-v5-before-adventure/`. Zatečeno stanje tog snimka je 185 XP, potrošeno 0 i devet misija; korisnikov napredak se u međuvremenu promenio u odnosu na istorijski izveštaj v5. Probna browser baza je `storage/v6-browser.sqlite3`, sa sintetičkim odgovorima za 12 misija i 1.740 XP. Testovi mogu da koriste `TEST_DATABASE_PATH`; podrazumevano ostaje `storage/test.sqlite3`.

## Provere v6

Pun `bin/check` prolazi na izdvojenoj `storage/v6-full-test.sqlite3`: 138 Rails testova / 2.854 tvrdnje, eager-load i 10 JavaScript provera geometrije. Dodatnih pet provera kontrola pisanja prolazi. Rezultati su `qa/v6/automatske-provere.txt` i `qa/v6/practice-controls.txt`. Početna zajednička provera otkrila je zastareo schema fajl, a zatim stari test koji je tražio značenje reči i za novu priču; obe stvari su ispravljene pre konačnog prolaza.

Production Rails/Rack provera prolazi na svežoj `storage/v6-production.sqlite3`: svih osam migracija, sve stranice i 14 direktnih CSS/JS resursa, svih 12 zadataka kroz HTTP sa CSRF zaštitom, 145 XP, odbijanje ponovnog nagrađivanja, tri moći, sačuvan otkriven potez, odbijanje zastarele aktivacije i ponovljene upotrebe. Odgovori/crteži su sintetički. Zapis je `qa/v6/production-check.txt`; to nije javni hosting.

Migraciona provera na kopiji v5 baze očuvala je sve stare kolone i redove u sedam tabela, uključujući započetu v3 misiju. Zatim je napravljen dodatni neposredni backup `development-before-v6-apply.sqlite3` u istoj arhivi i primenjene su migracije 000700/000800 na glavnu bazu. Poređenje svih prethodnih podataka potvrđuje neizmenjeno stanje: 185 XP, potrošeno 0, devet misija, isti odgovori i tekući zadatak. Dokazi su `qa/v6/upgrade-check.txt`, `main-migration.txt` i `main-preservation.txt`.

U browseru su na izdvojenoj bazi ručno provereni sva tri tipa priče, namerna greška u veličini/predmetu, ponavljanje stvarnim crtanjem malog а sa rezultatom 100 i bez XP, povratak na istu priču i tačan izbor sa 10 XP. Proverene su naočare uz osvežavanje, aktiviranje štita i blokiran udarac, neutralna raketna runda i nedostupna druga upotreba. Mapa i nove scene pregledane su na 1280 i 320 px, bez horizontalnog prelivanja. Glavna mapa prikazuje postojećih 9/16 koraka, dva spasena druga i aktivnu misiju na 4/12, uz nula zabeleženih JavaScript grešaka.

Detaljne granice, sintetički koraci i snimci nalaze se u `qa/v6/PROVERA.md`. Fizički Android, iPhone, olovka, Docker i javni hosting nisu provereni.

## Dogovor

Dete ima 7 godina, prepoznaje malo slova i već ih uči u školi. Cilj je mnogo smislene vežbe uz zabavu, vidljive nagrade i kolekciju delova dinosaurusa. Velika i mala štampana ćirilica, bez pisanih slova. Miš, prst ili kompatibilna olovka. Browser na računaru, Androidu i iPhoneu; nema zasebne mobilne aplikacije. Plain Rails, SQLite, bez frontend frameworka, prijave i više profila. Hosting nije zatražen u ovom koraku.

## Osnova do v5

Rails 8.1.4 / Ruby 3.4.8, minimalna Rails struktura. SQLite, server-rendered ERB, lokalni CSS/font/SVG i mali JavaScript moduli. Svih 30 slova i 60 vođenih oblika, uz banku od 38 reči sa 3–6 slova.

Nova misija ima 12 zadataka: dva pisanja jednog slova, dva pisanja cele reči slovo po slovo, dve dopune nedostajućih slova rukom, dva čitanja uz izbor slike, dva zadatka pamćenja, jedno sastavljanje cele reči sa dva suvišna slova i jednu dopunu rečenice. Tri ciljna slova vraćaju se kroz različite igre; reči sadrže i druga slova. Posle početna tri ciljna slova uvodi se najviše jedno novo uz dva ranije uvedena. Vizuelni primer je odvojen od stvarnog odgovora.

Pisanje cele reči proverava svako slovo zasebno. Pri dopuni je najmanje pola reči vidljivo, a nedostaju jedno ili dva slova. Dete za prazninu bira jedno od četiri ponuđena slova i zatim ispisuje izabrani oblik; trag tačnog slova nije prikazan pre izbora. Proveravaju se i izbor i geometrija svakog obaveznog slova. Posle tačne reči otvara se velika slika sa reči i kratkom rečenicom o njenom značenju, pre dugmeta za nastavak.

Prva greška na redovnom zadatku ubacuje kratko obavezno ponavljanje neposredno pre njega. Posle ponavljanja dete se vraća na isti zadatak. Najviše tri dodatna koraka, odnosno do 15 koraka u novoj misiji. Ponavljanje daje 0 XP; greška na ponavljanju ili ponovna greška na istom zadatku ne ubacuje novo ponavljanje. Nema dugmeta za otkrivanje odgovora. Ispravka posle greške, sva vođena pisanja i dodatna ponavljanja ne povećavaju nivo pamćenja. Samostalan prvi tačan odgovor pri sastavljanju, čitanju, rečenici ili pamćenju može da podigne nivo najviše jednom u 12 sati po slovu.

Memorijski zadatak nema prinudni tajmer. Dete samo pritisne „Zapamtio sam”; server trajno beleži da je reč sakrivena za taj zadatak. Osvežavanje i drugi uređaj ne otkrivaju reč ponovo.

Nagrade: 10 XP za uspešan redovan izazov, 25 za završenu misiju; nova misija ukupno daje 145 XP i uz dodatna ponavljanja. Kolekcija ima 16 vidljivih delova dinosaurusa, zatim kristale. Radionica ima tri početne i tri kupovne boje, riku, ples, aktiviranje opreme i isticanje tek osvojene nagrade. Dinosaur reaguje na uspeh uz izabranu proslavu, energiju i zvuk. Mute i reduced-motion ostaju dostupni.

Prodavnica ima 17 izbora: šest početnih i 11 kupovnih. Dodata su tri dinosaurusa (triceratops 240 XP, stegosaurus 420 XP, robo-dino 600 XP), tri boje (ledena 120, lava 120, kosmička 180 XP), tri sveta (svemir 220, vulkan 260, okean 220 XP) i dve proslave (munje 160, komete 220 XP). Početni reks, zelena/plava/breskva, livada i zvezdice ostaju besplatni. Kupovina traži potvrdu, prikazuje otključavanje i odmah uključuje novi izgled.

Ukupno zarađeni XP od poslednjeg izričitog roditeljskog reseta ostaje u `Learner.xp` i određuje nivo. `xp_spent` beleži potrošnju, a `xp_balance = xp - xp_spent` raspoloživi iznos. Zaglavlje i prodavnica prikazuju raspoloživi XP, roditeljski pregled sva tri iznosa. Kupovina ne umanjuje nivo i ne menja slova ili osvojenu opremu. Cenu određuje server, kupovine su atomske i jedinstvene po predmetu: ponovljen zahtev ne naplaćuje ponovo, a istovremeni zahtevi ne mogu da prekorače budžet. Kupljeni izbori mogu ponovo da se uključe bez plaćanja, uključujući novu boju kroz postojeću radionicu.

Kupovine u svakoj kategoriji imaju zaseban redosled: reks → triceratops → stegosaurus → robo-dino; ledena → lava → kosmička; livada → svemir → vulkan → okean; zvezdice → munje → komete. Server traži sve prethodne plaćene izbore iste kategorije, a prikaz navodi prvi koji nedostaje. Besplatne početne boje ostaju dostupne. Ranije kupljeni kasniji izbori mogu da se koriste i bez prethodnih kupovina; migracija ne oduzima stari izbor. Prodavnica prikazuje odabranu kategoriju i zadržava je posle kupovine ili promene izgleda.

Svaka završena misija otključava jednu borbu u areni. Vrsta dinosaurusa, oprema i boja snimaju se pri pokretanju borbe. Promena izabranog izgleda ili reset opreme ne menjaju taj snimak. Dinosaur ima tri osnovna srca i po jedan dodatni život za svaki deo ili kristal osvojen u misijama; kupovine ne daju živote. Protivnik ima `3 + ceil(0,75 × broj delova i kristala)` života. Napad pobeđuje varku, varka štit, štit napad; isti potezi su nerešeni. Pogođeni dinosaur prvo gubi opremu u toj borbi, a kolekcija u radionici ostaje sačuvana. Runde, preostali životi i konačni ishod čuvaju se na serveru. Osvežavanje nastavlja istu borbu; završena borba se ne pokreće iznova. Arena ne donosi XP.

Oba reseta su izdvojena na roditeljski pregled `/progress`; dečja radionica nema ove kontrole. Reset dinosaurusa zahteva potvrdu i proveru verzije sklopa, uklanja osvojenu opremu i kristale i vraća zelenu boju. Čuva učenje, ukupni i potrošeni XP, kupovine i sve misije. Kupljene boje ostaju dostupne za izbor bez plaćanja; izabrani dinosaur, svet i proslava ostaju uključeni. Snapshot omogućava vraćanje prethodne opreme i dostupne boje dok se ne osvoji nova nagrada. Ponovljeni zahtev ne prepisuje sačuvanu kolekciju praznim stanjem. Prva nova nagrada posle reseta ponovo su čizmice.

Poseban reset XP-a i prodavnice traži označenu potvrdu, tačno upisano `RESET` i važeću `shop_generation`. U istoj transakciji postavlja XP i potrošnju na 0, briše kupovine, vraća nivo 1, reksa, zelenu, livadu i zvezdice i povećava generaciju prodavnice. Čuva slova, pokušaje, završene i aktivnu misiju, osvojenu opremu i sve borbe. Novi odgovor u aktivnoj misiji i dalje donosi XP, a ponovljeni stari odgovor ne vraća staru nagradu. Ponovljeni reset i stari kupovni formulari ne mogu da promene novo stanje. Ovaj reset nema poništavanje u aplikaciji. Stari snapshot reseta dinosaurusa još može da vrati opremu, ali ne može da vrati obrisanu plaćenu boju: tada se koristi zelena. Započeta borba zadržava istorijski izgled. Svi naši reseti izvođeni su isključivo nad izdvojenim probnim bazama.

Čuvaju se odgovori, rezultati, raspored ponavljanja, započeta misija, sakrivanje memorijske reči, nagrade, borbe, potrošnja XP, kupovine i izabrani izgled. Nedovršen crtež pre slanja ne čuva se na serveru. Dva uređaja koriste isti napredak i isti raspoloživi XP. Dupli i istovremeni odgovori ne dupliraju nagradu, kupovinu ili potez u borbi.

CSS i JavaScript adrese sadrže otisak sadržaja, a ugrađena browser import mapa primenjuje isti princip na zavisne module. Time izmenjeni fajl dobija novu adresu i browser ne spaja staru crtaću površinu ili stilove sa novim ekranom. Nema dodatnog build procesa niti biblioteke za ovo ponašanje.

## Arhive i baze

Pre prethodnih dorada sačuvani su izvor i konzistentan SQLite backup u `revisions/2026-10-11-124533-v1/` i `revisions/2026-10-11-132947-v2/`. Neposredno pre prodavnice sačuvana je `revisions/2026-10-11-141839-v3/`, sa `source.tar.gz` i `development.sqlite3`. Pre v5 sačuvana je `revisions/2026-10-11-v4-before-ux/`, takođe sa izvorom i konzistentnim snimkom baze. Arhive su izuzete iz Gita i Docker konteksta. Aktivna stara misija dobija nove preostale zadatke uz zadržane završene odgovore, cursor i XP; čak i kada je stari cursor veći od 12 ostaje bar jedan nov zadatak. Istorija završenih misija ostaje sačuvana. Migracije 000400/000500 dodaju kupovine, raspoloživi XP, izabrani izgled i vrstu dinosaurusa u snimku borbe bez oduzimanja postojećeg XP. Šesta migracija dodaje `shop_generation` sa početnom vrednošću 1; primenjena je na glavnu bazu bez resetovanja podataka.

Browser provera v3 koristi isključivo `storage/v3-browser.sqlite3`, odvojeno od glavne `storage/development.sqlite3` i automatske `storage/test.sqlite3`. Posle prve probne misije testna baza je dopunjena za pregled pune opreme: 16 misija, 16 delova i 2.320 XP. To je probni skup podataka.

Pri završnom čitanju za v3 glavna baza imala je 965 XP, sedam završenih misija, jedan deo, peach boju, generaciju sklopa 2 i 92 pokušaja. To je tada zatečeni stvarni napredak, a ne probni skup niti tvrdnja o trenutnom stanju v4. Stvarni napredak se tokom rada menjao.

Pri završnoj proveri v4 glavna baza i nova v3 arhiva obe imaju 1.110 ukupnih XP, osam završenih misija, peach boju i generaciju sklopa 2. Nova polja u glavnoj bazi imaju početne vrednosti: potrošeno 0 XP, reks, livada i zvezdice. Stvarni XP nije trošen u našim proverama. Ovi brojevi su snimak stanja u trenutku čitanja.

## Provere — v5

Pun `bin/check` prolazi: 101 Rails test / 2.218 tvrdnji i 10 JavaScript testova geometrije, bez neuspeha, grešaka ili preskočenih testova. Zapis je `qa/v5/automatske-provere.txt`. Dodatnih pet provera kontrola za pisanje prolazi u `qa/v5/practice-controls.txt`: prazan crtež i tačka nisu gotov oblik, sva obavezna slova moraju da se završe, brisanje jednog ne briše ostala, izbor slova ne otkriva odgovor, a slanje zaključava potrebne kontrole.

Ciljane backend i povezane regresione provere pre pune provere takođe su prošle: 49 testova / 629 tvrdnji, bez neuspeha, grešaka i preskočenih testova, na zasebnoj `storage/v5-backend-test.sqlite3`. Provereni su redosledi svih kategorija, ranije kupljeni izbori, budžet i konkurentne kupovine, potvrde reseta, konkurentni i ponovljeni reseti, kupovina istovremeno sa resetom, stari formulari, nastavak zarade u aktivnoj misiji, odsustvo ponovne nagrade i vraćanje opreme bez obrisane plaćene boje. Rezultati v4 ispod ostaju istorijski.

Production Rails/Rack provera v5 prolazi na novoj `storage/v5-production.sqlite3`: svih šest migracija, svih 17 prodajnih izbora, kupovina po redosledu i očuvana kategorija, validni zahtevi sa uključenom CSRF zaštitom, odbijanje pogrešne potvrde, uspešan HTTP reset XP-a i kupovina, očuvano učenje i istorijska borba, nastavak aktivne misije i odbijanje ponovljenih starih nagrada i formulara. Stara rezerva opreme može da se vrati, ali obrisana kupovna lava ne može. Glavna i test baza nisu otvarane; SHA-256 otisci pre i posle su isti. Zapis je `qa/v5/production-provera.txt`. Ovo je provera kroz Rails/Rack, bez HTTP servera, browsera ili stvarnog crtanja.

Posle ispravke keširanja naknadno je provereno svih 17 CSS/JS adresa production prikaza, uključujući osam modula import mape: otisci odgovaraju sadržaju i GET vraća 200. Zapis `qa/v5/static-assets-production.txt` nastao je samo čitanjem postojeće izdvojene QA baze.

U izdvojenom browser pregledu početnih probnih 1.160 XP kupovinom triceratopsa pada na 920, a zatim stegosaurusa na 500. Sledeći dinosaur se otključava tek posle prethodnog; za robo-dinosaurusa tada nedostaje 100 XP. Filtriranje kategorija radi. Prazan roditeljski formular sprečava reset izvornom validacijom browsera, bez promene 500 raspoloživih XP. Valjan reset nije potvrđivan klikom u browseru: zasebno je potvrđen HTTP proverom iznad i za browser bazu zaštićenom Rails skriptom.

Zaštićeni reset browser probnih podataka smanjio je ukupnih 1.160 i potrošenih 660 XP na 0 i podigao generaciju na 2, sa svim početnim izborima. Pre i posle ostali su isti brojevi: osam završenih misija, 96 pokušaja, 11 zapisa o slovima, osam delova, devet sesija i jedna borba; tekuća sesija 9 je sačuvana. Zapis je `qa/v5/reset-fixture-result.txt`. Posle toga u browseru je ispisano И sa rezultatom 100 i osvojeno novih 10 raspoloživih XP. To nije reset stvarnog napretka.

Posle ispravke keširanja u browseru je provereno pet tačnih odgovora i jedna namerna greška. Pored И, cela reč САТ ispisana je slovo po slovo: posle prvog slova provera još nije dostupna, brisanje А čuva ranije završeno С, a tek sva tri slova omogućavaju slanje. Prikazana je slika sata i značenje reči; saldo raste na 20 XP. Tačno čitanje КОЗА, pamćenje reči миш i dopuna КОЗА uz izbor i pisanje К i А podižu saldo na 30, 40 i 50 XP. Namerno pogrešna reč „кит” u rečenici ubacuje kratko ponavljanje, povećava broj koraka na 13 i ostavlja saldo 50. Preostali koraci završeni su zaštićenom QA skriptom radi pregleda nagrade: 145 XP za ovu misiju i deveti deo. To nije tvrdnja da je cela misija v5 odigrana ručno.

U slovarici pretraga „авион” uz mala slova prikazuje jednu karticu; „ззз” prikazuje prazno stanje, a „prikaži sve” vraća 30. Arena je proverena na širini 320 px: posle jednog poteza ostaje sedam delova oklopa i prikazana je druga runda. Na završnom prikazu kategorije boja ostaju vidljivi naziv i navigacija; širina dokumenta je 305 px na ekranu od 320 px, bez horizontalnog prelivanja. Snimci i precizne granice nalaze se u `qa/v5/PROVERA.md`.

Glavna baza je pri završnom čitanju za v5 upoređena sa arhivom pre ove dorade: obe imaju 1.110 ukupnih XP, potrošeno 0, osam završenih misija, peach boju, reksa, livadu, zvezdice i nula kupovina. U našim proverama stvarni XP nije trošen niti resetovan. Brojevi opisuju trenutak čitanja, a ne budući napredak.

## Provere — v4 (istorija)

Pun `bin/check` prolazi: 88 Rails testova / 1.974 tvrdnje i 10 JavaScript testova geometrije, bez neuspeha, grešaka ili preskočenih testova. Zapis je `qa/v4/automatske-provere.txt`. Obuhvaćeni su nedovoljan i tačan budžet, cene sa servera, kupljeno/besplatno opremanje, ponovljena kupovina bez naplate, istovremene kupovine bez prekoračenja, rollback neuspelog čuvanja, očuvanje kupovina posle reseta, dopuna XP učenjem i odsustvo kupovnog bonusa u borbi. Snimak borbe zadržava ranije izabranu vrstu dinosaurusa i boju.

Završna ciljana shop controller provera prolazi: tri testa / 48 tvrdnji (`qa/v4/shop-final-test.txt`). Provera JavaScript sintakse prolazi za `shop.js`, `fx.js`, `application.js`, `workshop.js` i `battle.js`.

Browser pregled je završen na izdvojenoj `storage/v4-browser.sqlite3`. Otkazivanje kupovine ne troši XP. Kupovina ledene boje smanjuje probnih 145 na 25 raspoloživih XP; stvarno ispisano slovo sa rezultatom 100 donosi 10 XP, pa je stanje 155 ukupno i 35 raspoloživo. Za širi pregled probna baza je zatim pripremljena na osam misija, 1.160 ukupnih XP i osam delova. Kupovine triceratopsa, svemira, kometa i okeana ostavljaju raspoloživih 140 XP; besplatno ponovno biranje i Back/osvežavanje ne naplaćuju ponovo niti ponavljaju otključavanje. To su QA podaci, ne stvarni napredak deteta.

Komete stvaraju 28 čestica pri otključavanju i koriste se u radionici. Ledeni triceratops nosi osam osvojenih delova i ulazi u arenu sa 11 života prema protivnikovih 9. Posle poteza koji skida jedan deo i dalje je prikazan triceratops. Pregledani su desktop 1280 px, uski prikazi 390 i 320 px; na 320 px document scrollWidth je 305 px, bez horizontalnog prelivanja. Popravljeni su mobilna navigacija i prelivanje dijaloga. Nema zabeleženih JavaScript grešaka. Dokazi, konačni snimci i granice nalaze se u `qa/v4/PROVERA.md`.

Production Rails/Rack provera v4 prolazi na novoj `storage/v4-production.sqlite3`: svih pet migracija, prodavnica sa 17 kartica, stvarna CSRF zaštita, kupovina, jednokratno otključavanje, besplatno ponovno biranje, početna strana/radionica/slovarica i novi CSS/JS fajlovi. Probnih 600 ukupnih XP posle kupovine triceratopsa i svemira ostaje 600, nivo 7; potrošnja je 460 i raspoloživo 140. To je sintetički QA skup, ne dečji napredak. Glavna i test baza nisu otvarane, a njihovi SHA-256 otisci ostali su isti. Zapis je `qa/v4/production-provera.txt`; provera nije koristila HTTP server, browser ili HTTPS.

Četiri vrste sa različitim brojem delova i tri nove palete pregledane su kroz 15 SVG prikaza u `qa/shop-species/`. Pregledi `species-overview.png`, `equipment-overview.png` i `palette-overview.png` prikazuju razlike oblika, opremu i boje.

## Provere — v3

- Pun `bin/check`: 69 Rails testova / 1.788 tvrdnji i 10 JavaScript testova geometrije; bez neuspeha, grešaka i preskočenih testova. Eager-load prolazi. Zapis je `qa/v3/automatske-provere.txt`.
- Obuhvaćeni su svi tipovi zadataka, svako obavezno pisano slovo, pogrešan izbor za prazninu, ponavljanje pre pogrešnog zadatka i njegovih 0 XP, trajno sakrivanje memorijske reči, značenje reči, nadogradnja stare misije, dupli i konkurentni odgovori, reset i vraćanje kolekcije. Arena ima provere poteza, ishoda, čuvanja opreme, pristupa samo završenoj misiji i konkurentnih zahteva.
- U stvarnom ugrađenom Chromiumu završena je nova misija sa dve namerne greške: 14 koraka, 145 XP i jedan deo. Provereni su pisanje cele reči velikim i malim slovima, dopuna prvo pogrešno izabranim pa tačnim slovom, pamćenje uz osvežavanje i prikaz značenja posle reči.
- Odigrana je borba sa početnih 4 prema 4 života: pobeda posle 10 rundi, otpadanje dela, osvežavanje i sačuvana kolekcija. Za prikaz pune opreme pripremljena je odvojena borba sa 19 života dinosaurusa i 15 protivnika.
- Za proveru poraza posebna probna borba je servisom dovedena na jedan preostali život, a poslednji potez odigran je u browseru: 0 života, sakriveni potezi, kolekcija sačuvana i dostupna nova misija. Zatim je u browseru ispisana cela МАЧКА, počev od poslednjeg slova: prelazak na prvo nedovršeno slovo radi, svih pet oblika ima rezultat najmanje 95, odgovor daje 10 XP i dovodi sliku i rečenicu u vidljivi deo ekrana. Nema zabeleženih JavaScript grešaka; četiri modula prošla su proveru sintakse.
- Snimci pisanja i značenja reči na uskom ekranu, kao i arene na desktopu i na širini 320 px, nalaze se u `qa/v3/`. Detalji i granice su u `qa/v3/PROVERA.md`.
- Production Rails/Rack provera na izdvojenoj `storage/v3-production.sqlite3` prolazi: tri migracije, početna strana/radionica/slovarica/zadaci/nagrada/arena vraćaju HTTP 200, sakrivanje memorijske reči ostaje posle novog GET zahteva, dupli potez ne ponavlja rundu, 11 statičkih fajlova vraća 200. Probna misija završena je sa 145 XP, jednim delom i jednom borbom. Ovo nije pokretanje javnog servera niti provera HTTPS-a; zapis je `qa/v3/production-provera.txt`.

Raniji `qa/PROVERA.md` i `qa/v2/PROVERA.md` čuvaju rezultate prethodnih verzija. Njihova pravila o pomoći, odloženom ponavljanju i dodatnom XP nisu pravila v3.

## Granice i nastavak

Dogovorena roadmapa je u [ROADMAP.md](ROADMAP.md). Četiri stavke su isporučene u v6; zvučni vodič i predlog pripreme lokalnih audio-snimaka ostaju odloženi.

Korisnikov pregled i detetova reakcija određuju prihvatanje igre. Pedagoški učinak nije dokazan tehničkim testovima. Procena pisanja je geometrijska pomoć: ne potvrđuje pravilan školski smer ili redosled poteza i ne prepoznaje slobodan rukopis. Pravila intervala su heuristika aplikacije.

Govorni izgovor zahteva instaliran srpski Web Speech glas. Na ovom računaru nije dostupan, pa je provereno obaveštenje i nastavak igre bez izgovora. Zvučni efekti nagrada rade nezavisno. Za pouzdan izgovor na svakom uređaju moguća kasnija dorada su lokalni snimci slova, reči i uputstava.

Nisu provereni fizički Android, iPhone ni olovka, Docker build ni javno postavljanje. Mobilne širine u Chromiumu ne potvrđuju stvarni mobilni browser. HTTP odgovori imaju timeout od 18 sekundi; simulacija dužeg prekida mobilne mreže nije izvođena. Za otvaranje i čuvanje potrebna je veza sa serverom; nema offline sinhronizacije. Svi posetioci iste hostovane instance dele napredak, po izričitom dogovoru bez prijave. Za hosting treba trajni SQLite disk i HTTPS. Pokretanje i backup objašnjeni su u `README.md`.
