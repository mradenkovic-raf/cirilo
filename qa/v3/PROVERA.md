# Provera verzije v3 — 2026-10-11

## Automatski rezultat

Pun `bin/check` prolazi: 69 Rails testova, 1.788 tvrdnji i 10 JavaScript testova geometrije; 0 neuspeha, grešaka i preskočenih testova. Rails eager-load takođe prolazi. Ceo izlaz je u [automatske-provere.txt](automatske-provere.txt).

Provere obuhvataju raspored 12 zadataka, zasebnu proveru svakog slova pri pisanju, izbor nedostajućeg slova, odsustvo rasta nivoa pamćenja na vođenom pisanju, obavezno ponavljanje pre pogrešnog zadatka, 0 XP za ponavljanje, ograničenje od tri ponavljanja, značenje tačne reči, trajno sakrivanje memorijske reči, nadogradnju stare misije i očuvane nagrade. Obuhvaćeni su i dupli/konkurentni zahtevi, reset i vraćanje kolekcije, pravila arene, čuvanje rundi i ishoda, kao i zaštita od ponovljenog poteza.

Geometrijski testovi pokrivaju svih 30 slova u oba štampana oblika, sitno odstupanje, nedostajući potez, škrabanje, prazne/tapkane crteže, odvojene poteze i tačku malog ј. Ovi testovi ne proveravaju fizičku olovku ni školski rukopis.

## Probna misija u browseru

Provera je izvedena u stvarnom ugrađenom Chromiumu na izdvojenoj bazi `storage/v3-browser.sqlite3`, port 3002. Stvarni napredak iz `storage/development.sqlite3` nije korišćen za probne odgovore.

Završena je nova misija svih tipova sa dve namerne greške: ukupno 14 koraka i tačno 145 XP, uz prvi osvojeni deo. Provereno je:

- Pisanje celih reči, slovo po slovo, velikim i malim štampanim slovima.
- Dopuna nedostajućih slova: pre izbora nema traga rešenja; izbor pogrešnog slova daje njegov trag za pisanje, a tek potvrda odgovora ocenjuje izbor. Posle pogrešnog odgovora odigrano je kratko ponavljanje, zatim isti zadatak sa tačnim slovom.
- Dve greške dodaju dva obavezna koraka ponavljanja, bez dodatnog XP. Originalni zadatak ostaje za rešavanje odmah posle ponavljanja.
- Memorijska reč je sakrivena preko „Zapamtio sam”; posle osvežavanja ostaje sakrivena i zadatak može da se dovrši.
- Sastavljanje, izbor slike i dopuna rečenice, uz veliku sliku, ispisanu reč i kratku rečenicu posle tačnog odgovora.
- Završetak misije i prelazak na nagradu i arenu.

Snimci: [pisanje cele reči](whole-word-mobile.jpg), [dopuna slova](missing-letters-mobile.jpg), [značenje reči na uskom ekranu](word-meaning-mobile.jpg) i [značenje reči na desktopu](word-meaning-desktop.jpg).

Dodatno je u browseru ispisana cela МАЧКА, počev od poslednjeg А. Posle čuvanja poslednjeg slova površina je automatski prešla na prvo nedovršeno М; završena su i ostala slova, sva sa rezultatom najmanje 95. Tačan odgovor doneo je 10 XP, a kartica sa slikom i rečenicom automatski je postala vidljiva. Snimak: [značenje napisane reči](written-word-meaning-desktop.jpg). Nema zabeleženih JavaScript grešaka; četiri modula prošla su proveru sintakse.

## Arena

Odigrana je borba sa jednim delom opreme, odnosno početnih 4 života dinosaurusa i 4 života protivnika. Završena je pobedom posle 10 rundi. Tok obuhvata otpadanje dela, osvežavanje sa zadržanim stanjem i proveru da kolekcija u radionici ostaje sačuvana. Borba ne dodaje XP.

Za vizuelni prikaz pune opreme probna baza je zatim dopunjena na 16 završenih misija, 16 delova i 2.320 XP. Nova borba zato ima 19 života dinosaurusa i 15 života protivnika. Ovo je pripremljen probni skup, a ne korisnikov rezultat.

Snimci: [arena sa punom opremom](battle-desktop.jpg), [arena na širini 320 px](battle-mobile-320.jpg) i [pobeda na uskom ekranu](battle-victory-mobile.jpg).

Poraz je proveren zasebno: probna borba sa 16 delova dovedena je servisom na jedan preostali život, pa je poslednji potez odigran kroz stvarni browser. Rezultat je poraz sa 0 života, uklonjenim dugmadima za poteze, sačuvanom kolekcijom i dostupnim nastavkom kroz novu misiju. To proverava završni tok poraza; nije cela druga borba odigrana ručno. Snimak: [poraz na desktopu](battle-defeat-desktop.jpg).

## Production Rails/Rack provera

Zasebna provera u `RAILS_ENV=production` prolazi na `storage/v3-production.sqlite3`. Prazna baza dobila je sve tri migracije. Početna strana, radionica, slovarica sa 30 slova, pisanje reči, dopuna slova, nagrada i arena vraćaju HTTP 200. POST za sakrivanje memorijske reči vraća 200, a sledeći GET ne otkriva reč. Kreiranje borbe vraća 303; potez vraća 200, a dupli zahtev ostavlja istu prvu rundu bez dodatne štete ili XP. Svih 11 proverenih statičkih fajlova vraća 200.

Probni završetak ima 145 XP, jednu misiju, jedan deo i jednu borbu. Misija je za ovu proveru dovršena pomoću probnih podataka i sintetičkih validnih rezultata crtanja. Glavna baza je čitana pre i posle i nije promenjena u ovoj proveri; zajednička test baza nije otvarana. Detalji: [production-provera.txt](production-provera.txt).

Zahtevi su slati neposredno kroz Rails/Rack integration session, bez pokretanja HTTP servera ili browsera. Provera potvrđuje production konfiguraciju, HTML/JSON i isporuku navedenih fajlova; ne proverava izvršavanje browser JavaScripta, HTTPS/reverse proxy, Docker, javni hosting niti stvaran rukopis. Prvi pomoćni skript prekinut je zbog greške u samoj proveri; ispravljen je i ponovljen na izdvojenim podacima, bez izmene aplikacionog koda.

## Očuvanje podataka i prethodna verzija

Pre dorade sačuvani su `revisions/2026-10-11-132947-v2/source.tar.gz` i konzistentan SQLite backup `revisions/2026-10-11-132947-v2/development.sqlite3`. Starija v1 arhiva ostaje dostupna. Automatizovane provere koriste `storage/test.sqlite3`, browser provera v3 koristi `storage/v3-browser.sqlite3`, a korisnikov napredak ostaje u `storage/development.sqlite3`.

Pri završnom čitanju stvarna baza imala je 965 XP, sedam završenih misija, jedan deo, peach boju, generaciju sklopa 2 i 92 pokušaja. Stvarni napredak se tokom rada promenio; ovi brojevi su trenutni snimak, ne tvrdnja da je baza nepromenjena od arhive. Naše probne misije i reset nisu izvođeni nad tom bazom.

Aktivne stare misije dobijaju preostale zadatke v3 uz očuvane završene odgovore i XP. Zato ranije započeta misija ne mora imati iste ukupne XP kao nova misija v3. Raniji QA izveštaji ostaju istorijski zapisi; stara pomoć i odloženi zadaci sa XP nisu deo v3.

## Granice provere

- Nisu korišćeni fizički Android, iPhone niti prava olovka. Uzak viewport u Chromiumu potvrđuje raspored na toj širini, a ne kompatibilnost sa Safari/Chrome mobilnim uređajem.
- Pisanje je vođeno praćenje sa geometrijskom procenom, ne prepoznavanje slobodnog rukopisa. Smer i redosled poteza nisu kriterijumi ocene.
- Izgovor zavisi od instaliranog srpskog Web Speech glasa. Na ovom računaru nema tog glasa; provereno je obaveštenje i nastavak bez izgovora. Zvučni efekti nagrade su zasebni.
- Nije izvedena simulacija dužeg prekida mobilne mreže. Zahtevi imaju timeout od 18 sekundi; za čuvanje je potreban Rails server. Nema offline sinhronizacije.
- Docker build, javni hosting i stvarna production instalacija v3 nisu provereni. Gore opisana production provera koristi Rails/Rack i izdvojenu SQLite bazu, bez servera, HTTPS-a ili reverse proxy-ja.
- Provere potvrđuju ponašanje aplikacije u navedenim uslovima. Ne dokazuju detetovo razumevanje, dugoročno pamćenje niti motivaciju; to ostaje za korisnikov pregled i stvarno korišćenje.
