# Ћирило — dino-radionica

Rails aplikacija za decu koja uče srpsku ćirilicu. Obični server-rendered HTML, CSS i mali JavaScript moduli; bez Reacta, Vuea, frontend build procesa, prijave i profila. SQLite čuva zaseban napredak svakog browsera, a trajni šifrovani kolačić omogućava nastavak igre.

## Školska slova — v20

Podrazumevana igra koristi **А, М, И, Т, О, Н, С, Е**. U **Još → Za roditelja → Šta vežbamo?** roditelj bira poslednje naučeno slovo po redosledu bukvara ili označava pojedinačna slova. Druga opcija, **Cela azbuka**, zadržava dosadašnju igru. Izbor se pamti u bazi za isti browser; nema prijave i nema novih servisa.

Redosled: **А М И Т О Н С Е Р Ј У Ш Л Љ З В Г П К Д Б Њ Х Ж Ч Ћ Ф Ц Џ Ђ**. Igra sama ne dodaje školska slova. Reči, ponuđeni odgovori, pogrešna slova, rečenice, dopune i ponavljanje koriste samo roditeljev izbor. I slovarica prati taj izbor. Uputstva i ostali tekst interfejsa nisu ograničeni tim skupom.

Školska banka ima **423 kratke reči od 2–6 slova**, od kojih je 388 do pet slova. Skup do Е ima 67 reči, uključujući kratke glagole i imena za sastavljanje po sećanju. Za slikovne zadatke koriste se samo ilustrovani pojmovi; slike koje mogu isto da se protumače ne nude se zajedno. Kratke rečenice poput „Мама има сат“ zahtevaju prepoznavanje i osobe i predmeta. Prostorne priče ulaze tek kada su sva slova njihovog teksta poznata.

Misija i dalje ima 12 zadataka i uobičajenih 145 XP: deset zadataka čitanja/rada sa slovima i dve kratke vežbe pisanja. Na najranijim i vrlo uskim proizvoljnim skupovima nema dovoljno reči/slika, pa se nedostupne igre zamenjuju vežbama slova i pamćenja. Širinu sadržaja proveravamo kroz 42 misije (šest dnevno tokom nedelju dana); to nije dnevna obaveza niti ograničenje igranja. Ponavljanje reči kroz različite igre je namerno.

Dinosaurus, XP, kupovine, mapa i drugari zajednički su za oba načina igre. Započeta misija čuva svoj izbor slova i ostaje ista; roditeljska promena važi od sledeće. Potpuni restart briše napredak, ali zadržava roditeljev način igre i školska slova. Ranije sačuvane misije ostaju sa celom azbukom. [Provere i sačuvana verzija](qa/v20/PROVERA.md).

## Pokretanje na ovom računaru

```bash
cd /home/milos/ChatGPT/Mica
bin/dev
```

Otvori `http://127.0.0.1:3000`. Ruby 3.4.8 je već instaliran lokalno u `.runtime/ruby`, a gems u `vendor/bundle`. `bin/dev` pronalazi lokalni Ruby, proverava zavisnosti, priprema bazu i pokreće server. Zaustavljanje: Ctrl+C. Ako je port zauzet, već pokrenuti pregled može i dalje da radi; druga instanca može da koristi `PORT=3002 bin/dev`.

Za telefon na istoj kućnoj mreži:

```bash
BIND=0.0.0.0 bin/dev
```

Na telefonu otvori `http://IP-ADRESA-RAČUNARA:3000`. Računar i telefon moraju biti na istoj mreži; lokalni firewall mora da dozvoli ovaj port. Ovo nije zasebna Android/iPhone aplikacija. Potezi koriste Pointer Events, pa prihvataju prst, miš i olovku koju pregledač prepoznaje kao pointer.

## Napredak po browseru — v15

Pri prvom otvaranju browser dobija slučajan, šifrovan ključ u trajnom `HttpOnly` / `SameSite=Lax` kolačiću. U SQLite bazi čuva se samo njegov SHA-256 otisak. Nema korisničkog imena, prijave, biranja profila niti prepoznavanja uređaja preko IP adrese. Telefon i računar na istoj mreži zato imaju odvojene igre.

- Isti browser na istoj adresi nastavlja svoje slovo, misiju, mapu, dinosaurusa, kupovine i borbu. Obična Rails sesija može da istekne bez gubitka pristupa napretku.
- Drugi browser, drugi browser profil i privatni prozor dobijaju novi početak. Dva deteta koja koriste isti browser dele taj jedan napredak.
- Brisanje kolačića ili podataka sajta znači novi početak bez automatskog vraćanja. Podaci ostaju u bazi, ali browser više nema njihov ključ. Politika browsera može da skrati trajanje kolačića; „trajni” nije garancija da nikad neće biti obrisan.
- Koristi istu adresu: `localhost`, `127.0.0.1`, LAN IP računara i budući domen imaju različite kolačiće. Različiti portovi istog hostname-a dele kolačiće, pa za probnu aplikaciju koristi odvojeni hostname ili browser profil.
- Sva tri roditeljska reseta važe samo za trenutni browser. Potpuni restart zadržava njegov ključ, a briše njegov napredak. Drugi browseri i stari rezervni napredak ostaju netaknuti.
- Misije i borbe se traže isključivo među podacima vlasnika kolačića. Tuđi identifikator vraća 404; nevažeći ili nedostajući ključ odbija upis i traži ponovno otvaranje igre. Lične stranice se ne keširaju kao javni sadržaj.

Po korisnikovom izboru **svi kreću od nule**. Raniji zajednički napredak ostao je u bazi bez ključa za pristup i u konzistentnoj rezervnoj kopiji `revisions/2026-10-12-v14-before-device-progress/development.sqlite3`. Nema automatskog preuzimanja tih podataka.

Pre promene napravljen je Git commit `ce45f7f`, tag `v14-stable-before-device-progress` i grana `device-progress` za nove izmene. Tag čuva kod, a prethodno navedena kopija čuva podatke. Povratak zahteva **i stari kod i staru bazu**, uz zaustavljen server; migracija ne pokušava da više browsera stopi u jedno dete. Postupak je u [qa/v15/PROVERA.md](qa/v15/PROVERA.md). Rezervna baza i ključevi nisu u Gitu. Git i arhiva su za sada lokalni na ovom računaru.

## Šta radi

- V14: pregledano je svih 60 velikih/malih štampanih oblika; ispravljena su 42 skupa poteza prema srpskim bukvarima. Brojevi početka imaju strelice smera; numeracije koje dele isti početak razmaknute su. Aktuelne putanje koriste i već sačuvani zadaci pisanja reči/dopune, bez promene pitanja, odgovora, cursor-a ili XP-a. [Izvori i pregled svih slova](qa/v14/IZVORI-POTEZA.md). Ocena i dalje meri oblik, ne kažnjava drugačiji redosled poteza.
- Banka ima 112 reči: za svako slovo najmanje tri koje njime počinju, većinom četiri. Naredne misije rotiraju te primere; započeta misija čuva svoje reči. Slične slike ne pojavljuju se kao međusobni odgovori (npr. auto/džip, nos/njuška/njuh). Duže reči imaju prilagođen mobilni prikaz i ne prelamaju se usred ponuđenog odgovora.
- V13: protivnik je podešen za oko 75% pobeda u celoj borbi bez posebnih moći. Pomoć zavisi od početnih života, bez garantovanog ishoda. Naočare čuvaju otkriven potez, moći i jaka oprema mogu dodatno da pomognu. Cilj se podešava preko `BattleOpponent::TARGET_VICTORY_CHANCE`.
- V12: arena pokazuje tri velika srca i pojedinačne komade oklopa. Pogodak označava samo izgubljenu ikonu uz „−1 ОКЛОП” ili „−1 СРЦЕ”; potrošene ikone ostaju prazne, a sva zarađena oprema ostaje u kolekciji.
- V11: slika predmeta stoji uz slova dok dete piše reč. Umesto trake napretka njegov opremljeni dinosaurus ide po tačkama ka Mrgudu; dodatno ponavljanje produžava stazu. Arena jasno pokazuje pobedu uz medalju, zvezdice i melodiju, odnosno poraz uz poseban zvučni signal. Završnica sama dolazi u vidljivi deo ekrana; osvežavanje ne ponavlja slavlje. [Provere](qa/v11/PROVERA.md).
- Jaje v10: izaberi jednog od tri mala dinosaurusa u dvorištu, završi tri naredne misije, izlegni ga i daj mu ime. Napredak se pamti bez roka; potpuni restart briše jaje i pratioca, delimični reseti ih čuvaju. Izleganje ne troši niti daje XP.

- Dečji prikaz v8: početna pokazuje trenutni cilj spasavanja, Klika, sledeću nagradu i jedno veliko dugme za igru. Meni ima „Igra”, „Moj dino” i „Još”; mapa, prodavnica, slova i roditeljske opcije nalaze se u dodatnom meniju. Radionica drži kolekciju i promenu izgleda u sklopljenim odeljcima. Prodavnica ističe sledeći izbor u redosledu, a ostale pokazuje na dodir. Zadaci imaju jedno kratko uputstvo; opcije se pojavljuju kada su potrebne. Detaljne provere i snimci: [qa/v8/PROVERA.md](qa/v8/PROVERA.md).
- Svih 30 srpskih slova, velika i mala štampana; 60 oblika za praćenje.
- V17: nova misija ima 12 zadataka — 10 za čitanje i rad sa slovima, 2 za pisanje. Čitalački deo sadrži po dva čitanja reči uz izbor slike i razumevanja kratke rečenice, pa po jedno biranje naziva sa slike, sastavljanje reči, popravku slova, spajanje tri para, dopunu rečenice i sastavljanje po sećanju. Na drugom koraku dete bira položaj predmeta; na jedanaestom ostaje priča o veličini, mestu ili radnji. Jedno praćenje slova ostaje na četvrtom koraku; na desetom se kroz misije smenjuju pisanje cele reči i dopuna rukom. Svako ciljno slovo vraća se četiri puta. Reči uglavnom imaju 3–6 slova, uz tri primera od osam slova. Započete misije formata 3/4/5/6/7 čuvaju pitanja, redosled, XP i stanje pamćenja; novi odnos dobija naredna misija.
- Tri nove igre v9: „Koja reč ide uz sliku?” nudi četiri stvarne reči sa sličnim pisanjem; „Popravi reč” traži da dete samo pronađe jedno pogrešno slovo i zameni ga; „Spoji reči i slike” traži sva tri para pre zajedničke provere. Spajanje koristi dodir reči pa slike, bez prevlačenja. Veze mogu da se menjaju i vrate; neutralne oznake ne otkrivaju tačnost. Slike nikada nisu sve unapred poravnate sa rečima. Ceo zadatak parova donosi 10 XP, bez dodatnog XP po paru i bez pripisivanja znanja jednom slovu. Detalji: [qa/v9/PROVERA.md](qa/v9/PROVERA.md).
- Mala priča traži razumevanje i predmeta i njegove osobine, mesta ili radnje: npr. „Узми малу лопту”, „Пронађи јабуку у ранцу” ili „Покажи мачку која спава”. Ovih 12 rečenica ostaje. V17 dodaje još 20: jabuka/lopta × ranac/kutija × **u, na, pored, ispred, iza**. Prostorni zadatak prikazuje četiri različita položaja istog predmeta i iste posude, pa dete mora da pročita odnos; naziv predmeta ne otkriva odgovor. „U/na” i „ispred/iza” namerno se pojavljuju zajedno među izborima. Svih 20 kombinacija prolazi kroz naredne misije pre ponavljanja; slike se mešaju, a sačuvani zadatak ne menja odgovor pri osvežavanju. Banka ukupno ima 32 rečenice. Tačan odgovor donosi uobičajenih 10 XP, ali ne podiže nivo pamćenja proizvoljno izabranog slova.
- Pri dopuni je bar pola reči vidljivo. Za svaku prazninu dete prvo bira jedno od četiri slova, pa ispisuje izabrano slovo. Trag tačnog odgovora nije prikazan unapred. Svako obavezno slovo proverava se zasebno: dobar crtež jednog slova ne nadoknađuje izostavljeno ili pogrešno slovo.
- Posle tačno rešene reči pojavljuju se velika slika, reč i kratka rečenica o njenom značenju, pre prelaska na sledeći zadatak.
- Svaka misija posebno vežba tri ciljna slova; zatim uvodi najviše jedno novo ciljno slovo uz dva ranije uvedena. Reči sadrže i druga slova. Slova za ponavljanje i ona sa slabijim rezultatom imaju prednost.
- Slova se vraćaju u istoj misiji među drugim zadacima, i ponovo u budućim misijama.
- Aplikacija pamti konkretne zamene slova: izričit pogrešan izbor pri dopuni ili tačno jednu zamenjenu poziciju u sastavljenoj reči. Više različitih grešaka u reči ne proglašava jednom zabunom, a ispravke posle greške i zadaci za dodatno ponavljanje ne dodaju dokaze. U sledećim misijama poznati par ima prednost: pojavljuje se kratko poređenje oblika pri pisanju, a slovo sa kojim je dete pogrešilo ulazi među ponuđene odgovore. Dva samostalna uspeha iz prvog pokušaja u dve različite misije povlače par iz prioritetnog ponavljanja. Nova zamena ga ponovo aktivira. Ovo je praćenje odgovora deteta, ne dijagnoza.
- Geometrijska procena pisanja meri pokrivenost, preciznost i potpunost oblika. Ne ocenjuje smer i redosled poteza. Prag je 65/100 uz minimalnu pokrivenost i dužinu crteža.
- Vođeno pisanje jednog slova, cele reči i dopuna rukom računaju se kao vežba pisanja. Nivo pamćenja raste samo za samostalan tačan odgovor iz prvog pokušaja pri sastavljanju, čitanju, izboru naziva slike, popravci reči, rečenici ili pamćenju. Napredovanje jednog slova najviše jednom u 12 sati, sa razmacima 6 sati, 1/3/7/14/30 dana. Ovo je praktično pravilo aplikacije, a ne standardizovan test znanja.
- Prva greška na redovnom zadatku nove misije vraća dete na jedno kratko obavezno čitalačko ponavljanje, pa odmah na isti zadatak. Ponavlja se poslednji rešeni čitalački zadatak; ako ga još nema, dete čita reč za trenutno slovo i bira sliku. Pisanje ne postaje dodatna kazna. Ranije sačuvane misije zadržavaju svoj prethodni način ponavljanja. Najviše tri takva ponavljanja po misiji: ukupno najviše 15 koraka. Ponavljanje ne donosi XP; greška na samom ponavljanju ili ponovna greška na istom zadatku ne ubacuje novo ponavljanje. Ispravka posle greške i dodatna ponavljanja ne podižu nivo pamćenja. Nema oduzimanja već osvojenih nagrada niti dugmeta koje otkriva odgovor.
- Kod pamćenja dete samo bira kada da pritisne „Zapamtio sam”. Server tada trajno sakriva reč za taj zadatak: ostaje sakrivena i posle osvežavanja ili otvaranja u drugom tabu istog browsera. Nema prinudnog tajmera niti ponovnog pokazivanja reči.
- Tačan redovan zadatak donosi 10 XP, završena misija dodatnih 25 XP. Nova misija ukupno donosi 145 XP, i kada ima dodatna ponavljanja. Prvih 16 nagrada trenutnog dinosaurusa otključava 16 delova; posle njih stižu kristali energije.
- Prodavnica troši osvojeni XP na nove dinosauruse, boje, svetove i efekte proslave. Kupovina čuva ukupan zarađeni XP i nivo; za kupovinu je dostupan ukupan XP umanjen za već potrošeni XP. Prodavnica prikazuje raspoloživi iznos, a roditeljski pregled sva tri iznosa. Nema plaćanja novcem.
- Radionica prikazuje stečene delove, pamti boju i ima tri reakcije: rika, ples i aktiviranje opreme. Uspešan zadatak pokreće skok dinosaurusa, energetski dobitak, konfete i zvuk. Isključenje zvuka i sistemski zahtev za smanjenim animacijama poštuju se.
- Roditeljski pregled sadrži tri odvojena reseta. Reset dinosaurusa vraća opremu, kristale i boju na početak; naučena slova, ukupan i potrošen XP, kupovine, završene i tekuća misija ostaju. Mapa i spaseni drugari ostaju. Izabrani dinosaur, svet i efekat ostaju uključeni. Kupljene boje mogu ponovo da se izaberu bez plaćanja. Prva naredna nagrada ponovo su čizmice. Prethodna oprema i dostupna boja mogu da se vrate dok nije osvojena nova nagrada.
- Reset XP-a i prodavnice zahteva označenu potvrdu i tačno upisano `RESET`. Briše zarađeni i potrošeni XP i sve kupovine, vraća nivo 1, reksa, zelenu boju, livadu i zvezdice. Čuva naučena slova, odgovore, misije, osvojenu opremu i borbe. Započeta misija nastavlja da zarađuje XP za nove odgovore; već nagrađeni odgovor ne daje XP ponovo. Ovaj reset nema dugme za poništavanje.
- Potpuni restart u roditeljskim opcijama briše sav napredak: XP, kupovine, opremu i rezervu za vraćanje, borbe, završene i aktivnu misiju, odgovore, vežbana slova i njihove zamene. Mapa se vraća na 0/16, a dvorište na 0/4 drugara. Vraća početni izgled, traži potvrdu i tačno `RESET`, važi samo za trenutni browser i nema poništavanje. Stare misije, borbe, kupovni formulari i ponovljena potvrda restarta ne mogu vratiti obrisane podatke niti obrisati novo učenje.
- Svaka završena misija otključava jednu borbu u areni. Pri ulasku se snime izabrani dinosaur, boja i osvojena oprema; kasnija kupovina ili promena izgleda ne menjaju već započetu borbu. Dinosaur ima tri osnovna srca i još jedan život za svaki deo ili kristal osvojen u misijama. Protivnik ima `3 + ceil(0,75 × broj delova i kristala)` života. Kupovine izgleda ne daju dodatne živote. Napad pobeđuje varku, varka štit, a štit napad; jednaki potezi su nerešeni. Oprema koja otpadne gubi se samo u toj borbi, a kolekcija u radionici ostaje sačuvana. Arena pamti runde i ishod posle osvežavanja; završena borba se ne pokreće ponovo i ne donosi XP.
- Započeta misija se nastavlja posle osvežavanja stranice ili ponovnog otvaranja istog pregledača na istoj adresi, dok je kolačić sačuvan. Crtež koji još nije poslat se ne čuva; već poslati odgovori se čuvaju.
- Roditeljski pregled prikazuje vežbana slova, ponavljanja i završene misije.
- Mapa avanture ima četiri sveta sa po četiri koraka: šuma, pećina, vulkan i svemir. Završena misija otvara jedan korak, a četvrti korak svakog sveta spasava malog dinosaurusa. Mapa ne donosi dodatni XP i ne dozvoljava preskakanje misija. Detalji su ispod.
- Spaseni drugari pojavljuju se u dvorištu oko Klika u radionici: Lisko se igra loptom, Iskra slaže svetleće kristale, Žarko gradi kulu, Zvezdan sprema raketu. Imaju animirane aktivnosti i lični pozdrav na dodir; klik ne daje XP. Vidljivi su samo već spaseni drugari. Završetak spasavanja vodi do radionice, a ona pokazuje i koliko misija ostaje do sledećeg drugara. Utišavanje i smanjeno kretanje važe i ovde.
- Zarađena oprema daje tri posebne moći u areni: naočare otkrivaju jedan protivnikov potez, svetlosni štit zaustavlja jedan pogodak, a rakete preskaču jednu rundu bez gubitka života sa obe strane. Svaka moć može da se upotrebi jednom u borbi; detalji su ispod.

Zvuci nagrade nastaju u pregledaču, bez zvučnih fajlova i servisa. Izgovor koristi Web Speech API **samo ako postoji srpski glas na uređaju**; inače prikazuje jasno obaveštenje, a tekst i ikone ostaju dostupni bez zvuka. Zvučni vodič sa unapred pripremljenim srpskim snimcima izričito je odložen; plan je sačuvan u `ROADMAP.md`, ali ti snimci nisu deo v6. Pravi izgovor nije potvrđen na Androidu/iPhoneu. Svi fontovi i vizuelni elementi su lokalni. Za otvaranje i čuvanje misije potrebna je veza sa Rails serverom; nema offline sinhronizacije.

CSS i JavaScript koriste adrese sa otiskom sadržaja. Ugrađena browser import mapa povezuje i zavisne module sa njihovom aktuelnom verzijom, bez build procesa. Posle izmene fajlova browser tako dobija nove stilove i skripte umesto mešanja starih i novih verzija.

## Mapa avanture

`/adventure` prikazuje jedan put sa 16 koraka. Posle četvrte misije Lisko je pronađen u šumi; posle osme Iskra izlazi iz pećine; posle dvanaeste Žarko prelazi vulkan; posle šesnaeste Zvezdan se vraća na svoju planetu. Trenutni korak otvara ili nastavlja istu postojeću misiju. Budući koraci i svetovi su zaključani; prethodni koraci služe prikazu uspeha i ne mogu ponovo da se naplate.

Napredak se izvodi iz već sačuvanog broja završenih misija, bez pretvaranja XP-a: na primer, devet završenih misija znači pređenu šumu i pećinu, spasena prva dva drugara i jedan od četiri koraka vulkana. Izbor kupljene teme aplikacije ne menja svet do kog je dete stiglo na mapi. Reset XP-a, prodavnice ili dinosaurusa ne vraća mapu unazad. Zaseban potpuni restart vraća i mapu i sve drugare na početak.

Posle svih 16 koraka mapa ostaje završena. Dugme „Vežbaj dalje” pokreće ili nastavlja običnu misiju sa postojećim nagradama, bez ponovnog spasavanja ili posebnog bonusa sa mape. Ekran završene misije prikazuje korak koji je ta misija otvorila; otvaranje stare završene misije ne prikazuje današnji napredak kao novu nagradu.

## Posebne moći u areni

Moći pripadaju snimku opreme sa početka konkretne borbe. Naočare, svetlosni štit i raketne čizmice osvajaju se misijama; kupovina izgleda ne otključava njihove moći. Kasnije promene radionice ne menjaju tu borbu. Moć ostaje dostupna čak i kada deo njenog oklopa otpadne, ako nije već iskorišćena.

| Oprema | Jedna upotreba u borbi |
| --- | --- |
| Istraživačke naočare | Otkrivaju protivnikov potez za trenutnu rundu. Server ga čuva, pa osvežavanje ne izvlači novi potez. Dete zatim bira svoj potez. |
| Svetlosni štit | Čeka prvi naredni pogodak i potpuno ga zaustavlja, bez gubitka srca ili opreme. Ostaje spreman kroz pobede i nerešene runde. Ovo je posebna moć, odvojena od običnog poteza „Štit”. |
| Raketne čizmice | Odmah završavaju jednu neutralnu rundu: niko ne gubi život i dete u toj rundi ne napada. Aktivirani svetlosni štit ostaje spreman. |

Upotrebe, runde i otkriveni potez čuvaju se u SQLite bazi. Ponovljeni isti zahtev ne troši moć ili rundu ponovo, a zastarela stranica dobija aktuelno stanje. Moći ne daju XP i ne menjaju pravilo jedne borbe po završenoj misiji.

## XP prodavnica

Prodavnica ima 17 izbora: šest početnih i 11 koji se kupuju. Početni su reks, zelena/plava/breskva boja, livada i zvezdice. Kupovina traži potvrdu sa nazivom i cenom, odmah uključuje izabrani izgled i prikazuje otključanu nagradu. Kupljeni izbori mogu besplatno da se menjaju i ostaju dostupni dok roditelj izričito ne resetuje XP i prodavnicu.

| Kategorija | Novi izbori i cene |
| --- | --- |
| Dinosaurusi | Triceratops 240 XP; stegosaurus 420 XP; robo-dino 600 XP |
| Boje | Ledena 120 XP; lava 120 XP; kosmička 180 XP |
| Svetovi | Svemir 220 XP; vulkan 260 XP; okean 220 XP |
| Proslave | Munje 160 XP; komete 220 XP |

Svaka kategorija ima svoj redosled: reks → triceratops → stegosaurus → robo-dino; ledena → lava → kosmička; livada → svemir → vulkan → okean; zvezdice → munje → komete. Za novu kupovinu moraju biti kupljeni svi raniji plaćeni izbori u toj kategoriji. Početne tri boje ostaju besplatne. Izbor kupljen pre uvođenja ovog pravila i dalje može da se koristi i kada prethodni izbori nisu kupljeni.

Server proverava redosled, cenu i preostali budžet. Dupli zahtev za istu kupovinu ne naplaćuje ponovo, a istovremene kupovine ne mogu da potroše više od raspoloživog XP. Posle roditeljskog reseta server odbija stare formulare za kupovinu, promenu izgleda i ponovljeni reset. Izbor izgleda ne menja napredak slova, ukupan XP, nivo ili snagu u areni. Novi dinosaur nosi već osvojene delove opreme.

Reset XP-a i prodavnice ne briše staru rezervu opreme iz odvojenog reseta dinosaurusa: oprema još može da se vrati kada je vraćanje inače dostupno. Plaćena boja čija je kupovina obrisana ne vraća se iz te rezerve; koristi se zelena. Već započeta borba zadržava svoj raniji snimak dinosaurusa, boje i opreme.

## Na drugom računaru

Potreban je Ruby 3.4.x sa Bundlerom i razvojni alati za instalaciju gems. Korišćen je Rails 8.1.4. Verzije zavisnosti zapisane su u `Gemfile.lock`.

```bash
bin/setup
bin/dev
bin/check
```

`bin/check` radi Rails provere, Minitest i testove geometrije ako je Node dostupan. Node je potreban samo za te testove, ne za aplikaciju. Na ovom računaru koristi se postojeći Node iz Codex runtimea.

### Nadogradnja dok lokalni server već radi

Posle migracije koja menja kolone obavezno ponovo pokreni postojeći server. `bin/dev` priprema bazu pre novog pokretanja, ali migracija u drugom procesu ne osvežava uvek strukturu koju već pokrenuti Rails drži u memoriji. Lokalni Puma ima uključen `tmp_restart`, pa posle uspešne migracije možeš da uradiš `touch tmp/restart.txt`; alternativno zaustavi server i ponovo pokreni `bin/dev`. Osvežavanje browsera samo po sebi nije dovoljno.

Zatim proveri pogođenu radnju kroz taj pokrenuti server. Testovi i `rails runner` pokreću nove procese i zato mogu da prođu dok stari server još prijavljuje, na primer, `undefined method 'action_revision'`. Ne dodavati zamenska polja u model niti resetovati bazu zbog ove greške.

## Hosting i trajni podaci

Aplikacija se hostuje kao običan Rails/Puma proces. SQLite je podrazumevani izbor i u [Rails uputstvu](https://guides.rubyonrails.org/v8.1/getting_started.html). Nema dodatnog servera baze. Primer bez Dockera:

```bash
export RAILS_ENV=production
export SECRET_KEY_BASE="VREDNOST-KOJU-DOBIJES-KOMANDOM-bundle-exec-rails-secret"
export DATABASE_PATH=/trajni/direktorijum/cirilo.sqlite3
export APP_HOST=cirilo.tvoj-domen.rs
bundle exec rails db:prepare
bundle exec rails server -b 0.0.0.0 -p 3000
```

Kada hosting reverse proxy završava HTTPS, postavi `ASSUME_SSL=1` i `FORCE_SSL=1`. Dockerfile priprema aplikaciju za container hosting, a entrypoint rešava vlasništvo trajnog diska i spušta privilegije pre pokretanja Rails-a. SQLite mora biti na trajnom volume-u; na Railway-u startup odbija pokretanje bez njega. Koristi jednu aplikacionu instancu nad jednim SQLite fajlom.

**Railway:** igra je dostupna na [cirilo-production.up.railway.app](https://cirilo-production.up.railway.app). Podešavanja trial servisa i postupak sledeće objave su u [RAILWAY.md](RAILWAY.md). Javni GitHub repo je [mradenkovic-raf/cirilo](https://github.com/mradenkovic-raf/cirilo), produkciona grana je `main`; push trenutno ne pokreće automatski deploy. Workflow `Check` proverava Rails/JS i Docker. [Priprema](qa/v18/PROVERA.md), [provere javnog servisa](qa/v19/PROVERA.md).

Nema prijave: **svaki browser ima svoj napredak**. Javni servis koristi HTTPS i trajni SQLite volume; identifikacioni kolačić je u production režimu `Secure`. `SECRET_KEY_BASE` i SQLite baza moraju da opstanu pri svakom novom deploy-u; promena ključa poništila bi postojeće šifrovane kolačiće. Lokalni napredak ne prenosi se automatski na javni domen.

Baze su `storage/development.sqlite3`, `storage/test.sqlite3` i, ako nije naveden drugi put, `storage/production.sqlite3`. Za konzistentan backup koristi SQLite backup komandu, npr.:

```bash
sqlite3 storage/development.sqlite3 '.backup storage/backup.sqlite3'
```

Ne kopiraj samo glavni SQLite fajl tokom upisa: mogu biti aktivni i WAL/SHM fajlovi.

Za izdvojene provere koristi `TEST_DATABASE_PATH` uz `RAILS_ENV=test`; `DATABASE_PATH` podešava razvojnu ili production bazu, ne test bazu. Primer bez promene porodičnog napretka:

```bash
PATH="$PWD/.runtime/ruby/bin:$PATH" TEST_DATABASE_PATH=storage/provera.sqlite3 RAILS_ENV=test bin/rails db:prepare
PATH="$PWD/.runtime/ruby/bin:$PATH" TEST_DATABASE_PATH=storage/provera.sqlite3 RAILS_ENV=test bin/rails test
```

## Gde se menja sadržaj

- `config/alphabet.json`: slova, reči, ilustracije i putanje oblika u koordinatama 0–100.
- `app/controllers/application_controller.rb`, `app/models/learner.rb`: trajni ključ browsera, početak od nule i odabir njegovog napretka.
- `app/services/practice_planner.rb`: izbor i raspored zadataka.
- `config/words.json`, `app/services/word_bank.rb`: reči, slike, rečenice i ponuđeni odgovori.
- `app/services/story_bank.rb`, `app/helpers/story_helper.rb`: male priče i originalne slike za proveru razumevanja rečenice.
- `app/models/letter_confusion.rb`, `app/services/confusion_tracker.rb`: dokazi o konkretnim zamenama slova i samostalnim uspesima.
- `app/models/letter_progress.rb`: intervali ponavljanja.
- `app/services/attempt_recorder.rb`: validacija odgovora, XP, nagrade i zaštita od duplih upisa.
- `app/services/shop_catalog.rb`, `app/services/shop_service.rb`, `app/models/shop_purchase.rb`: ponuda, redosled otključavanja, cene, kupovine i raspoloživi XP.
- `app/services/shop_reset.rb`, `app/services/dino_reset.rb`: odvojeni roditeljski reseti prodavnice i opreme.
- `app/views/`: Rails HTML prikazi.
- `public/application.css`, `public/challenges.css`, `public/application.js`: izgled i tok zadataka.
- `public/writing.js`, `public/trace_pad.js`, `public/trace.js`: pisanje pojedinačnih slova i reči, crtaća površina i procena oblika.
- `public/workshop.css`, `public/workshop.js`: radionica i reakcije dinosaurusa.
- `app/services/battle_arena.rb`, `public/battle.js`, `public/battle.css`: pravila, čuvanje i prikaz borbe.
- `app/models/battle.rb`, `app/helpers/battles_helper.rb`: veza zarađene opreme i posebnih moći, njihov status i prikaz.
- `app/services/adventure_map.rb`, `app/helpers/adventures_helper.rb`, `app/views/adventures/`, `public/adventure.css`: četiri sveta, napredak misija i originalni SVG drugari.
- `app/helpers/dino_helper.rb`: originalni slojeviti SVG dinosaur i delovi.
- `public/shop.js`, `public/shop.css`, `public/themes.css`: kupovina, otključavanje i svetovi.
- `public/fx.js`, `public/fx.css`: proslave i vizuelni efekti.
- `qa/`: dokumentovane provere i snimci prikaza.

Font Nunito je pod SIL Open Font License; licenca je u `public/fonts/OFL.txt`. Azbučni inventar je proveravan prema [Srpskoj enciklopediji](https://srpskaenciklopedija.rs/books/slovo-a/page/azbuka). Dinosaur i delovi su napravljeni za ovaj projekat, bez korišćenja likova postojećih crtanih serija.

Lokalni Ruby i gems ostaju u projektu. Bundler je tokom sandbox provera automatski koristio privremene foldere u `/tmp`; jedan privremeni pregled dinosaurusa takođe je bio sačuvan u `/tmp/mica-dino-preview.png` i uklonjen posle provere. Aktuelni QA izlazi su u `qa/`.

## Provere i sačuvane verzije

Aktuelna v17 dodaje 20 prostornih rečenica i povećava broj kratkih priča sa jedne na dve u misiji, uz isti odnos 10 čitanja / 2 pisanja i 145 XP. Prošlo je 225 Rails i 29 JavaScript testova; [nalazi i mobilni prikaz](qa/v17/PROVERA.md). Prethodna v16 uvela je prednost čitanja i čitalačka ponavljanja posle grešaka; [nalazi](qa/v16/PROVERA.md). V15 uvodi odvojeni napredak po browseru. Provere izolacije, kolačića, nadogradnje stare baze i postupak povratka vode se u [qa/v15/PROVERA.md](qa/v15/PROVERA.md). Starije QA skripte koje pozivaju `Learner.current` pripadaju svojim sačuvanim verzijama; nisu ulaz za v15.

Istorijska verzija v7 dodala je živo dvorište za spasene drugare i zaseban potpuni restart. Prolazi **155 Rails testova sa 3.179 tvrdnji**, eager loading i 10 JavaScript provera geometrije. Prošli su i zasebna production HTTP/CSRF provera potpunog restarta, starih zahteva i početka novog učenja, kao i browser pregled na 1280 i 320 px. Detalji su u `qa/v7/PROVERA.md`. Pre izmene sačuvani su izvor i konzistentna porodična baza u `revisions/2026-10-11-v6-before-friends/`; svih osam tabela stvarnog napretka ostalo je nepromenjeno. Reset je izvršavan samo nad izdvojenim probnim bazama.

Prethodna v6 dodala je male priče za čitanje sa razumevanjem, vežbe prema zabeleženim zamenama slova, mapu avanture i posebne moći opreme. Detaljni nalazi su u `qa/v6/PROVERA.md`. Prethodna v5 zadržana je u arhivi, sa proverama u `qa/v5/PROVERA.md`. Ranije provere prodavnice su u `qa/v4/PROVERA.md`, a misije i arene u `qa/v3/PROVERA.md`. Pravi Android, iPhone i olovka još nisu provereni; provere u production režimu ne predstavljaju javno objavljivanje aplikacije.

Za v6 prolazi **138 Rails testova sa 2.854 tvrdnje**, eager loading, 10 JavaScript provera geometrije i pet provera kontrola za pisanje. Rezultati su u `qa/v6/automatske-provere.txt` i `qa/v6/practice-controls.txt`. Production HTTP provera svih novih tipova zadataka, posebnih moći i verzionisanih statičkih fajlova prošla je na izdvojenoj bazi uz CSRF zaštitu; izlaz je u `qa/v6/production-check.txt`.

Nadogradnja kopije sačuvane v5 baze na v6 prošla je uz nepromenjene podatke u svih sedam ranijih tabela, sa sačuvanim identifikatorima zadataka, kursorom i sakrivenom reči u aktivnoj staroj misiji, kao i tadašnjih 185 XP i devet završenih misija (`qa/v6/upgrade-check.txt`). U lokalnom browseru ručno su proverene sve tri vrste priče, sve tri moći na širini 320 px i mapa na 320 i 1280 px bez horizontalnog prelivanja. Pogrešan izbor u priči otvorio je obavezno ponavljanje: stvarno ispisano slovo prošlo je sa 100% i bez XP-a, zatim se vratio isti zadatak, čiji je tačan odgovor doneo 10 XP.

Istorijski rezultat v5 bio je 101 Rails test sa 2.218 tvrdnji, 10 JavaScript provera geometrije i pet provera kontrola za pisanje, uz zasebnu production Rails/Rack proveru kupovine i roditeljskog reseta.

Pre prethodnih proširenja sačuvani su izvorni fajlovi i konzistentan snimak tadašnje baze u `revisions/2026-10-11-124533-v1/`, `revisions/2026-10-11-132947-v2/` i, neposredno pre prodavnice, `revisions/2026-10-11-141839-v3/`. Pre v5 sačuvana je `revisions/2026-10-11-v4-before-ux/`, a neposredno pre v6 `revisions/2026-10-11-v5-before-adventure/`; obe imaju `source.tar.gz` i konzistentan `development.sqlite3`. Arhive služe povratku; nisu aktivna aplikacija. Započeta misija formata v3 ili v4 ostaje nepromenjena pri učitavanju; samo mnogo stariji formati dobijaju nove preostale zadatke uz zadržane završene odgovore i XP. Tokom naših provera reset je izvođen samo nad izdvojenim probnim bazama.
