# V17 — čitanje prostornih odnosa

Datum: 2026-10-12. Korisnik je zatražio više kratkih zadataka čitanja sa izborom slike, uz odnose u, na, pored, ispred i iza.

## Isporučeno

- 20 novih rečenica: jabuka/lopta × ranac/kutija × pet položaja. Primeri: „Јабука је у ранцу.”, „Лопта је на кутији.” i „Јабука је иза кутије.” Pravilni padeži su deo banke.
- Sva četiri odgovora imaju isti predmet, iste boje i isti ranac/kutiju; razlikuje se položaj. Pri izboru za u/na i ispred/iza obavezno je ponuđen i drugi član tog para. Pozicije odgovora se mešaju pri pravljenju zadatka i ostaju sačuvane tokom njegovog rešavanja.
- SVG prikazuje zaklanjanje predmeta prednjom ili bočnom ivicom posude, odnosno ceo predmet na vrhu, pored ili ispred. Nema opisa slika koji bi otkrivali odgovor niti izgovaranja tražene rečenice. Pregled svih scena: [kontakt-lista](position-sheet.png).
- Nova misija ima dve kratke priče umesto jedne. Prostorni zadatak je drugi korak, a jedna od 12 ranijih priča je jedanaesti. Postojeća druga vežba izbora naziva slike ustupa mesto prostornoj priči; jedan izbor naziva ostaje na kraju.
- Ostaju 12 redovnih zadataka, 10 čitanja/slova, dva pisanja i 145 XP. Posle greške ostaje čitalačko ponavljanje bez dodatnog XP-a. Priče ne podižu nivo pamćenja proizvoljno izabranog slova.
- Format novih misija je 7. Sačuvani formati 3–6 ne preuređuju se, uključujući redosled, identifikatore, XP, ponavljanja i sakrivenu reč. Promena se dobija od sledeće nove misije. Nema migracije ili reseta.

## Automatske provere

- **225 Rails testova / 14.391 tvrdnja**, bez grešaka: [veran rezime izvršavanja](rails-tests.txt), seed 32953. Korišćena samo `storage/v17-tests.sqlite3`.
- Posle poslednje dorade SVG oslonca zasebno ponovljen prikaz svih novih i starih scena: **3 testa / 566 tvrdnji**, [originalni zapis](story-render-tests.txt), seed 8204.
- Testovi proveravaju svih 20 rečenica, jedinstven tačan odgovor među četiri različita položaja, iste predmete, svih 12 ranijih priča, rotaciju narednih misija, odnos 10/2, 145 XP i očuvanje započetih V6 misija. Obuhvaćeni su nevažeći i ponovljeni odgovori, greška i recovery, bez duplog XP-a i lažnog napretka slova.
- **29 JavaScript testova**: [izlaz](javascript-tests.txt). [Eager loading](eager-load.txt) i `git diff --check` prolaze.

## Browser pregled

Pregled je rađen na `localhost:3002` sa izdvojenom `storage/v17-browser.sqlite3`. Glavni server koristi `127.0.0.1:3001`, pa browser kolačići probne i stvarne igre ostaju odvojeni.

1. Nova misija počinje čitanjem AUTO. Tačan izbor daje 10 XP; sledeći zadatak je „Јабука је у ранцу.” sa četiri položaja iste jabuke i ranca.
2. Vizuelno pregledan desktop i širina **320 px**. Rečenica i sva četiri izbora staju na mobilni ekran; nema horizontalnog prelivanja. Svako dugme je 126 × 112,5 px. [Desktop](spatial-desktop.png), [mobilni prikaz](spatial-320.png).
3. Namerno izabrana jabuka **na** rancu za rečenicu **u** rancu. Odgovor je odbijen; put je produžen 12→13. Kratko čitalačko ponavljanje AUTO daje 0 XP i vraća istu rečenicu sa istim izborima. Izbor jabuke u rancu daje 10 XP. [Uspeh](spatial-success-320.png).
4. Samo za dodatni vizuelni pregled na probnoj bazi sledeći zadatak je zamenjen sadržajem `StoryBank.position_exercise(variation: 14)`. „Јабука је иза кутије.” jasno razlikuje iza, ispred, pored i u kutiji na 320 px. Ovo je ručno postavljen QA primer, ne dokaz redovnog redosleda zadataka. [Prikaz](spatial-behind-320.png), [mere rasporeda](mobile-layout.json).

Probni server je posle pregleda zaustavljen, tab zatvoren i privremena širina browsera vraćena. Fizički Android/iPhone nisu proveravani. Tehničke provere ne potvrđuju pedagoški učinak; korisnikov pregled sa detetom tek sledi.

## Podaci i povratak

Pre rada napravljen je tag `v16-stable-before-spatial-reading` na `afc9f87`, konzistentna rezerva `revisions/2026-10-12-v16-before-spatial-reading/development.sqlite3` i grana `spatial-reading`. Kod i rezervna baza ostaju lokalni; baza i slike nisu u Gitu.

[Poređenje glavne baze](main-preservation.json) potvrđuje SQLite integritet i nepromenjenih sedam od osam tabela. U `learners` su se između snimka i provere promenili samo `egg_state` i `updated_at` zapisa 3: iz praznog stanja u izabrano, još neizleženo stego jaje. Izmena je zabeležena dok je glavni server ostao dostupan; uzrok nije utvrđivan. Nisu vraćani ti podaci. XP, ostala polja učenika, svi odgovori, misije, vežbana slova, oprema, borbe i kupovine ostali su identični. QA zahtevi i ručno postavljen primer korišćeni su isključivo na izdvojenoj bazi.

Tokom rada Bundler koristi privremene foldere u `/tmp`. Kontakt-lista scena prvobitno je napravljena kao `/tmp/mica-position-sheet.png` uz privremeni SVG, a pregledana slika je kopirana u ovaj QA folder. Trajni nalazi su ovde.
