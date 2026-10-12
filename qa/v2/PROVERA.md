# Provera proširene verzije — 2026-10-11

## Automatski rezultat

`bin/check`: 46 Rails testova, 1.433 tvrdnje; 10 JavaScript testova geometrije. Svi prolaze. Zapis je u `automatske-provere.txt`. `application.js` i `workshop.js` prolaze proveru JavaScript sintakse. Production smoke sa zasebnom bazom prolazi za `/`, `/workshop`, `/alphabet`, `/progress` (HTTP 200).

## Tok kroz browser

U stvarnom Chromiumu na odvojenoj bazi `storage/v2-browser.sqlite3`, port 3002, odigrana je cela nova misija. Korisnikova baza nije korišćena za probne odgovore/reset.

1. Mišem ispisano А; 100% i 10 XP.
2. Složeno pogrešno МИК umesto МИШ. XP ostao isti, zadatak ostao aktivan, zakazano ponavljanje (13 zadataka). Vraćeno samo К i dodato Ш; odgovor prihvaćen.
3. ИГЛА pročitana uz izbor slike. Zatražena pomoć; prikazana reč i slika, zakazano ponavljanje (14 zadataka). Pomoć zatim sakrivena; tačan odgovor prihvaćen.
4. ауто prikazano za pamćenje, sakriveno, ponovo pogledano; treće ponavljanje zakazano (15 ukupno). Sakrivena reč i složeno АУТО.
5. Mišem ispisano м (100%). Složena ИГЛА. Pročitana rečenica o vozaču i izabrano АУТО između ЗЛАТО/ЈАТО/АЛАТ. Pročitano МИШ i izabrana slika miša. Ispisano И (100%).
6. Ponovo sastavljeno АУТО. Rečenica o šivenju dopunjena rečju ИГЛА između ТЕГЛА/ИГРА/МАГЛА. МИШ složen po pamćenju.
7. Odloženi zadaci МИШ, ИГЛА, АУТО vraćeni sa drugim rasporedom slova/slika. Završetak: 175 XP, jedan deo (čizmice), tačna završna nagrada.
8. Link nagrade otvara radionicu sa istaknutim novim delom. Ples menja poruku i pokreće animaciju. Promena boje na plavu sačuvana.
9. Roditeljska kontrola: potvrđen reset probnog dinosaurusa; oprema 0/16, zelena boja, 175 XP sačuvano. Vraćanje prethodnih delova/boje: 1/16, plava boja, XP i istorija ostali sačuvani. Osvežavanje zadržava obnovljeno stanje.

## Vizuelni pregled

- Igre: 390 px, veliki čitljivi blokovi, vizuelni primer, pločice, rečenica i odgovor. Povratna poruka se dovodi u vidljivi deo ekrana.
- Radionica: 320 px i desktop. Na 320 px document scrollWidth=305 (viewport=320, ostatak scrollbar); nema horizontalnog prelivanja. Sve 16 kartica i roditeljska kontrola dostupni.
- Originalni SVG dinosaur: pregledano svih 17 stanja opreme i svih 16 ikona. Završni prikaz pune opreme je `dino-16.png`.
- Završni desktop screenshot radionice koristi stvarni sačuvani napredak: 500 XP, četiri dela. Nema zabeleženih browser JavaScript grešaka na toj strani.

## Granice

Ovo ne potvrđuje rad na fizičkom Androidu/iPhoneu ili pravoj olovci. Izgovor i dalje zavisi od instaliranog srpskog glasa. Nije izvedena simulacija prekida mobilne mreže; dodat je timeout od 18 sekundi uz postojeću zaštitu od duplih nagrada. Docker i javni hosting nisu pokretani. Detetova razumljivost zadataka, težina i interesovanje zahtevaju korisnikov pregled; tehnički uspeh to ne dokazuje.
