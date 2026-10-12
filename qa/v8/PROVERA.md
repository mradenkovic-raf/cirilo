# V8 — manje stvari, jasniji sledeći korak

Datum: 2026-10-11. Plain Rails, postojeći SVG/CSS/JavaScript; bez migracija ili novih servisa.

## Automatske provere

- `automatske-provere.txt`: eager loading, 155 Rails testova / 3.177 tvrdnji i 10 JavaScript testova geometrije; sve prolazi.
- `final-target-checks.txt`: posle poslednjih dorada 14 pogođenih Rails testova / 259 tvrdnji prolazi. Izolovana baza `storage/v8-full-test.sqlite3`.
- `writing-controls.txt`: pet testova pravih kontrola pisanja uz mali DOM/canvas stand-in; proveravaju obavezno dovršavanje svih slova, pokazivanje završne provere tek na kraju, brisanje, izričit izbor bez otkrivanja odgovora i zaključavanje tokom slanja.
- Nezavisan pregled izmena prema v7 arhivi nije našao regresiju JS selektora ili arena kontrola. Naknadno je browserom potvrđen i popravljen izgubljen fokus posle skrivanja izabranog slova.

## Browser pregled

Sve kupovine, odgovori i borbe izvođeni su na izdvojenoj `storage/v8-browser.sqlite3`, port 3002. `prepare.rb` pravi sintetički napredak sa 16 misija, punom opremom i četiri drugara. `advance.rb` sintetički prelazi na traženu vrstu zadatka. `fresh_preview.rb` vraća isključivo probnu bazu na početak. Sva tri skripta odbijaju drugačiji `DATABASE_PATH`.

- Širine 320, 390 i 1280 px; vizuelno pregledani početna, dvorište, prodavnica, mapa, pisanje, nagrada i arena. Provereni ekrani ne prelivaju horizontalno.
- Početna: jasan cilj, jedan veliki nastavak i mala sledeća nagrada; glavno dugme vidljivo bez skrolovanja na 320 × 740. Nastavak otvara istu aktivnu misiju.
- Dvorište: četiri stvarna druga, Liskov pozdrav u sceni, otvaranje i zatvaranje svih 16 delova. Provereno i prazno dvorište; postojeća dva druga proverena u glavnoj aplikaciji.
- Dodatni meni: otvara prodavnicu i slovaricu; nazivi ostaju uz ikone.
- Prodavnica: otvaranje i odustajanje od potvrde, probna kupovina triceratopsa za 240 XP, proslava i sledeći stegosaurus. Direktan `#item-dino_robo` otvara sklopljene buduće izbore, a server redosled ostaje obavezan.
- Arena: sva tri osnovna poteza i posedovane moći. Naočare otkrivaju protivnikov štit; varka ga pobeđuje i smanjuje oklop 12 → 11. Desktop prikaz ima dinosauruse pored komandi; telefon ih slaže po visini.
- Pisanje: slovo И nacrtano stvarnim potezima, ocena 100 i +10 XP. Cela СОВА nacrtana kroz četiri zasebna slova; provera se pojavljuje tek kada su sva dovršena, daje +10 XP i prikazuje sovu sa rečenicom značenja.
- Dopuna ЗЕЦ: izbor З skloni ponuđena slova i otvori trag za pisanje; „Promeni slovo” vraća ponudu i fokus. Izbor tastaturom sada prebacuje fokus na canvas, ne na body ili skriveni izbor. Pri vraćanju ponude status ponovo kaže „Izaberi slovo”.
- Nagrada: veliki predmet, osvojeni XP i glavno dugme za arenu; ostale akcije su diskretne.
- Mapa: stanje 0/16 i 16/16, jedan glavni cilj, otvaranje četiri koraka pojedinačnog sveta.
- Slovarica: filtriranje po ж i prelazak na mala slova; svih 30 slova ostaje dostupno.

Tokom provere privremeni serverski proces je ugašen pre slanja prvog crteža. UI je ispravno prikazao da odgovor nije sačuvan. Posle ponovnog pokretanja istog probnog servera isti crtež je prihvaćen bez gubitka i duplog XP-a. To nije bila greška u crtanju. Završni uzorak browser logova je prazan (`browser-logs.json`); to nije tvrdnja da je uzorak obuhvatio celu sesiju.

## Stvarni podaci i završetak

Arhiva pre izmena: `revisions/2026-10-11-v7-before-child-focus/source.tar.gz` i konzistentan `development.sqlite3`. `main-preservation.json` poredi sve redove svih osam tabela sa glavnom bazom: identično. Sačuvani su 290 ukupnih XP, 220 potrošenih, 10 završenih misija i dva druga. Stvarni napredak nije resetovan niti su u njemu rešavani probni zadaci.

Glavni server je ponovo učitan i nova početna/radionica proverene na portu 3000. Preview server i privremeni tab su zatvoreni; viewport override uklonjen. Korisniku ostaje glavna početna. Snimak `main-home.png` prikazuje stvarno stanje.

Snimci sa drugim imenima prikazuju izdvojene probne podatke. Fizički Android, iPhone, olovka, hosting i Docker nisu proveravani. Vizuelna i tehnička provera ne zamenjuju probu sa detetom.
