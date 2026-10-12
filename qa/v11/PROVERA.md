# V11 — slika uz pisanje, staza i ishodi arene

`check.txt`: 184 Rails testa / 6.114 tvrdnji i 23 JS testa, bez grešaka. Izolovana baza `storage/v11-full-test.sqlite3`. Dodatnih pet provera kontrola pisanja prolazi u `writing-controls.txt`.

Nove provere obuhvataju sliku pre odgovora, sačuvanu poziciju opremljenog dinosaurusa, pomeranje po stvarnom cursoru, dodavanje tačke posle greške, duple odgovore, oba završetka arene, fokus/prikaz, različite zvučne signale, mute i nedostupan audio. Audio test izvršava stvarni kontroler uz DOM/AudioContext zamene; nije potvrda zvuka na fizičkom telefonu.

Browser provera koristi samo `storage/v11-browser.sqlite3` na portu 3002. `prepare.rb` odbija drugu bazu. Prve dve misije i većina treće završene su servisom sa sintetičkim crtežima. Dve borbe su pripremljene sa jednim preostalim životom na odgovarajućoj strani, a njihovi završni potezi odigrani u browseru.

- Na 320 × 740 slika lisice stoji uz svih šest slova ЛИСИЦА. Promena na šesto slovo čuva sliku. Dokument ne preliva horizontalno; ovaj pregled nije ponavljao crtanje cele reči.
- Pogrešan izbor naziva slike u browseru zadržao je cursor 1 i promenio ukupno 12→13, sa 13 tačaka. Poslednji tačan odgovor u browseru pomera 12/13→13/13 i dino stiže do kraja. Odgovori između ova dva događaja dati su helperom.
- Oba završna poteza otvaraju odgovarajući rezultat, skrivaju kontrole i prebacuju fokus na naslov. Cela kartica staje u vidljivi deo ekrana na 320 px. Reload pobede zadržava rezultat bez `.is-revealing` i bez novog efekta.
- Desktop pregled arene na 1280 px nema horizontalno prelivanje. Uzorak browser logova nije imao greške.

Snimci `writing-path-320.png`, `path-complete-320.png`, `victory-320.png`, `defeat-320.png` i `victory-desktop.png` prikazuju probne podatke. Fizički Android/iPhone, olovka i reprodukcija preko njihovih zvučnika nisu provereni.

Arhiva pre rada: `revisions/2026-10-11-v10-before-play-feedback/`, izvor i konzistentna SQLite kopija. `main-preservation.json` poredi sve tabele: zapisi učenja, pokušaja, misija, delova, borbi i kupovina su identični. Učenik se razlikuje samo po boji green→blue i `updated_at`; ne vraćamo tu zatečenu promenu. Ukupnih 435 XP, potrošenih 220 i 11 završenih misija ostali su isti. Naši probni odgovori i borbe nisu menjali glavnu bazu. Nema migracije.

Glavni server je ponovo učitan; početna, novi CSS i import mapa potvrđeni na portu 3000, bez browser grešaka. Probni server i tab su zatvoreni, viewport vraćen. Glavna početna ostavljena je otvorena.
