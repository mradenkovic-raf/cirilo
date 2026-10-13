# V20 — školska slova i kratko čitanje

Datum: 2026-10-13. Novi podrazumevani režim koristi А М И Т О Н С Е. Cela azbuka ostaje dostupna u roditeljskim opcijama.

## Sadržaj

- 423 školske reči od 2–6 slova; 388 ima najviše pet slova. Imena i glagoli bez jasne slike služe za sastavljanje po sećanju.
- Skup do Е: 67 reči, 18 ilustrovanih pojmova i osam kratkih rečenica razumevanja. Osam namenskih crteža zamenjuje neprecizne emoji za osu, soma, stenu, sto, seno, sito, testo i nit.
- Svaki naredni korak otvara nove reči sastavljene samo od dotadašnjih slova. Tačan redosled i brojevi za svih 30 koraka su u [content-audit.json](content-audit.json). Nismo morali da koristimo dozvoljene izuzetke sa budućim slovima.
- Svaka puna školska misija ima 10 zadataka čitanja/rada sa slovima i dve odvojene vežbe pisanja. Jedno slovo ili veoma uski proizvoljni izbor imaju manje različitih tipova zadataka; nedostupne slikovne igre zamenjuje sastavljanje po sećanju.
- Osoba i predmet u novim rečenicama čine četiri kombinacije. Samo prepoznavanje osobe ili predmeta ne određuje odgovor. Prostorne priče se koriste tek kada su sva slova rečenice poznata.

## Automatske provere

`RAILS_ENV=test TEST_DATABASE_PATH=storage/v20-test.sqlite3 bin/check` prolazi: **264 Rails testa / 75.007 tvrdnji**, **29 JavaScript testova** i Zeitwerk provera. Izlaz: [check.txt](check.txt).

Pokriti su oba režima, čuvanje roditeljskog izbora, nevažeći/prazni zahtevi, zastareli formular, tuđi browser, trajni cookie, kompletna misija, arena, SVG prikaz i značenje posle odgovora. Školski zadaci provereni su za svih 30 prefiksa i svih 30 pojedinačnih slova. Nezavisni dodatni pregled obuhvatio je i svih 435 parova slova. Nepoznato slovo ne ulazi ni kroz ponuđene pogrešne odgovore, pisanje, popravku, zabeležene zamene ili dopunsku vežbu posle greške.

[content_audit.rb](content_audit.rb) odigrava **42 stvarne misije** kroz planer i zapisivanje odgovora u test transakciji: 504 zadatka, **44 različite ciljane reči**, osam rečenica i 42 različite kombinacije misije. Od toga je 420 zadataka čitanja i 84 pisanja; rezultat je 6.090 XP i 42 nagrade. Transakcija se poništava. Šest misija dnevno je provera širine sadržaja, ne dnevni zahtev. Ovo ne dokazuje obrazovni učinak ili da će dete nedelju dana biti podjednako zainteresovano.

## Browser

Provera na zasebnoj bazi `storage/v20-browser.sqlite3` i adresi `localhost:3002`, odvojenoj od glavnog browser cookie-ja za `127.0.0.1`:

- Roditeljske kartice na postojećoj širini pregleda i 320 px; čuvanje „do Р“, pojedinačno isključivanje Р i povratak na podrazumevani skup. Nema horizontalnog prelivanja.
- Prava školska misija: izbor slike, namerna greška, dodatni korak 12→13, tačan odgovor, vraćanje originalnog zadatka, XP i slika značenja.
- „Мама има сат“: četiri jasne ilustracije, izbor mame sa satom uspešno prihvaćen. [Snimak na 320 px](school-reading-mobile.png).
- Namenski crtež stola u slaganju reči i u završnoj kartici značenja; reč složena dodirima, odgovor sačuvan. Za pregled crteža napravljena je posebna probna misija sa osam dodatnih zadataka; produkcione misije ostaju dužine 12.
- Nema zabeleženih JS upozorenja/grešaka u proveravanim tokovima. Nismo proveravali fizički iPhone/Android niti ceo ciklus pisanja prstom; protokol pisanja i postojeći JS testovi prolaze.

## Podaci i sačuvana verzija

Pre izmene: Git tag `v19-stable-before-school-mode`, grana `school-learning`, konzistentna SQLite kopija u ignorisanom `revisions/2026-10-13-v19-before-school-mode/development.sqlite3`.

Migracija prvo isprobana na kopiji te baze. [migration-check.json](migration-check.json) potvrđuje iste redove i identične vrednosti svih starih kolona, uz ispravnu SQLite bazu. Stare misije dobijaju `learning_mode=full`; roditeljski izbor postaje `school`, do Е. Poeni, napredak i pitanja se ne prepisuju.

Neposredno pre migracije glavne lokalne baze napravljena je još jedna kopija `before-local-migration.sqlite3` u istom direktorijumu arhive. Posle migracije ponovo su upoređeni svi stari redovi i kolone: nema promene. Glavna aplikacija je pokrenuta na `127.0.0.1:3001`. Probni odgovori nisu upisivani u glavnu bazu.

Roditeljsko podešavanje i sadržaj misije odvojeni su: misija čuva režim i izabrana slova, pa promena roditelja važi za sledeću misiju. Dinosaurus, mapa i nagrade zajednički su za oba režima. Kompletan reset briše napredak, ali čuva roditeljev izbor i povećava reviziju da stari formular ne može da ga prepiše.

Za povratak na prethodno stanje treba zaustaviti server i koristiti zajedno tag v19 i odgovarajuću rezervnu bazu. Time bi se odbacio napredak nastao posle rezervne kopije; zato trenutnu bazu prvo sačuvati. Baze i ključevi nisu deo Gita.

Ova verzija je lokalna; Railway servis i javni `main` nisu ažurirani ovim radom. Nema novih zavisnosti, spoljnih servisa niti troška za slike ili govor.
