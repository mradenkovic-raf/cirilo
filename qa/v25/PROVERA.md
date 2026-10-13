# V25 — više reči, ilustracija i raznovrsnije čitanje

Status: lokalno završeno, nije objavljeno na Railwayu. Prethodna javna verzija ostaje v24 (`349d1de`); početna Git tačka ovog rada je `1cfceb1`.

## Sadržaj

| Banka | Pre | Sada |
| --- | ---: | ---: |
| Školske reči i oblici | 543 | 781 |
| Reči do Е | 75 | 120 |
| Slikovni odgovori do Е | 24 | 37 |
| Školske rečenice do Е | 8 | 20 |
| Lokalne SVG ilustracije | 30 | 50 |
| Reči u režimu cele azbuke | 112 | 160 |

Od 781 školske reči/oblika, 710 ima najviše pet slova (90,9%); ostale imaju šest. Novi rani slikovni odgovori su ОМОТ, СТАН, МАНТА, ТОТЕМ, СМЕТ i osam množina: НИТИ, НОТЕ, ОСЕ, СИТА, СТЕНЕ, МОНЕТЕ, АНТЕНЕ, СЕМЕНА. To nisu 13 potpuno novih pojmova. Množine dele grupu sa jedninom i zato ne mogu da budu dvosmisleni konkurentski odgovori. САТИ je trajanje, ne slika više časovnika; АТОМ i БРАВА takođe su samo tekstualni.

Proširenje cele azbuke dodaje 48 reči koje imaju jasne slike i rečenice za dopunjavanje. Tamo gde emoji nije dovoljno određen (npr. sito, testo, som), koristi se ista lokalna ilustracija kao u školskom režimu. Slika se prenosi u sastavljanje, pisanje, dopunu, popravku, čitanje, spajanje i potvrdu značenja; pamćenje je i dalje skriva.

## Raznovrsnost

Planer pamti reči iz poslednjih šest školskih misija, uključujući prethodni izbor naučenih slova. Svaka reč broji se jednom po misiji; sva tri odgovora iz spajanja ulaze u praćenje tekuće misije. Slika→reč daje prednost sličnim početnim slovima i dužinama, uz nepromenjenu proveru različitog značenja. Dve priče do Е u istoj misiji više ne pitaju za isti predmet kod mame i tate.

[Simulacija 42 misije](content-audit.json), pomoću [izdvojenog runnera](content_audit.rb):

- 504 zadatka, 42 različite misije;
- 66 različitih ciljnih reči, svih 37 slikovnih reči i svih 20 rečenica do Е;
- nijedna ciljna reč ponovljena unutar iste misije, najviše četiri zajedničke ciljne reči između susednih misija;
- 420 čitalačkih i 84 pisaća zadatka, 6.090 XP i 42 redovne nagrade.

Simulacija ima rollback i radi samo u test okruženju. Broj misija je provera raznovrsnosti, ne preporuka koliko dete treba da igra. Provera ne meri da li dete zaista bolje čita.

## Tehničke i vizuelne provere

- [Kompletna provera](check.txt): 307 Rails testova / 118.832 tvrdnje, bez grešaka; 62 JavaScript testa, svi prolaze.
- Ciljana provera smenjivanja predmeta u pričama prolazi [28 testova / 59.383 tvrdnje](story-rotation-check.txt): priče, školski planer i kontroler podešavanja/toka.
- Tri nove regresije planera potvrđeno padaju nad prethodnim planerom i prolaze sa izmenom: starija istorija, sve reči iz spajanja i slični ponuđeni počeci.
- Svih 30 kumulativnih etapa i proizvoljni skupovi ostaju u naučenim slovima. Provereni su duplikati, dužine, normalizacija, dostupnost slika, XML i odsustvo aktivnog sadržaja u SVG fajlovima.
- Dvadeset novih SVG ilustracija renderovano i pregledano kao kontaktni list. Dodatno su u stvarnom Rails prikazu na 390 px pregledane nove slike unutar priče „Мама има семе”, a na 320 px čitanje „ОМОТ”, nove opcije i slika posle tačnog odgovora. Obe vrste zadatka prihvatile su odgovor i dale uobičajenih 10 XP.
- Na 320 px nema horizontalnog preliva, slike su učitane; browser nema prijavljene JS greške/upozorenja. Snimci su `story-seeds-390.png`, `new-pictures-320.png`, `word-meaning-320.png` u ovom folderu (lokalno, izuzeti iz Gita).

Probni browser koristi `storage/v25-browser.sqlite3` i localhost:3025. [Priprema pojedinačnog zadatka](prepare.rb) odbija bilo koju drugu bazu. Testovi koriste `storage/v25-test.sqlite3`, a audit `storage/v25-audit.sqlite3`; stvarni napredak nije korišćen ili resetovan. Nema migracije, promene nagrada ili novih spoljnih servisa. Sačuvane misije ostaju iste, a nova banka važi od sledeće misije. Fizički Android/iPhone nisu provereni u ovom koraku.
