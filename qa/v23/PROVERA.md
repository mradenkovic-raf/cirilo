# Railway objava — 2026-10-13

Korisnik je izričito odobrio deploy. Objavljene su sve lokalne promene v20–v22: školski režim, proširena banka i prostorne vežbe, vožnja, štit, muzika/efekti, autić na putanji i jasnije naočare.

- URL: https://cirilo-production.up.railway.app
- Kod: `11ebe3bbf890ddf9b9d5c2f8b5058d882032c4c9` sa GitHub `main`.
- Deployment: `9a85c6fb-c07d-4cfb-b879-48193ee37849`, **SUCCESS**.
- [GitHub CI](https://github.com/mradenkovic-raf/cirilo/actions/runs/38462454309): oba posla uspešna; 298 Rails testova / 93.412 tvrdnji, 58 JS testova, production proxy/browser persistence, Docker sa praznim root-owned volume-om i nastavkom iste misije posle zamene containera. [Sažet izlaz](ci-check-summary.txt).
- [Potvrda deploya i resursa](deployment.json): isti servis, jedna replika, 0,5 vCPU / 500 MB, isti volume od 500 MB u Holandiji, uključeno uspavljivanje, nema staged izmena.

## Rezerva i migracije

Nije bilo SSH ključa, pa nisu dodavani novi pristupni ključevi ili plaćeni backup servis. Ugrađen je mali hook pre `db:prepare`: ako postojeća baza ima nove migracije, SQLite backup API napravi konzistentan snimak sa WAL podacima, prebaci kopiju na samostalni journal, proveri integritet i atomarno je sačuva. Direktorijum je 0700, fajl 0600. Jedan snimak po ciljnoj verziji, bez prepisivanja; greška zaustavlja migracije. Nove/potpuno migrirane baze preskaču kopiranje. Pet testova obuhvata WAL, idempotentnost i neuspehe.

Runtime log za ovaj deployment potvrđuje: `Migration backup verified and saved for target 20261013000200.` Rezerva je `/app/storage/migration-backups/production.sqlite3-before-20261013000200.sqlite3`. Nalazi se na istom volume-u i nije zasebna rezerva protiv gubitka diska. Nisu menjani `SECRET_KEY_BASE`, putanja baze ili mount.

Migracije dodaju školska podešavanja i tabelu vožnji. Stare misije zadržavaju svoj sadržaj i punu azbuku; sledeće koriste roditeljski izabrana slova, podrazumevano do Е. Nije resetovan napredak.

## Provera javne aplikacije

Pre i posle objave `tmp/v19-public-state.json` je omogućio pristup istoj namenskoj probnoj misiji preko samo stalnog cookie-ja, bez novog odgovaranja ili menjanja podataka. Skripta [public_release_check.py](public_release_check.py) dodatno potvrđuje HTTPS `/up`, import mapu, SHA-256 i verzije cache-a za `game_audio.js`, `battle.js`, `dino_drive.js`, `mission_path.js`, kao i školske opcije do Е. [Rezultat](public-check.txt). Cookie ostaje lokalno u ignorisanom fajlu 0600 i nije ispisan niti poslat u Git.

U stvarnom browseru otvorena je javna početna, bez igranja ili menjanja roditeljskih opcija. Prikaz radi, konzola nema greške/upozorenja. [Snimak](public-home.jpg). Kompletni tokovi vožnje/arene bili su provereni lokalno u v21/v22; nisu ponovo igrani na tuđem napretku u produkciji. Fizički telefon i subjektivni kvalitet zvuka nisu dodatno proveravani.

## Povratak i naredne objave

Prethodna živa verzija bila je v19 (`614aff2`). Posle novih školskih misija i vožnji jednostavan povratak samo koda na v19 nije kompatibilan: nedostaju školski prikazi i obrada zavisnih vožnji pri resetu. Ne pokretati `db:rollback` nad živim podacima. Za grešku samo u v22 koristi kompatibilni v21 (`acdc013`) ili novu ispravku. Vraćanje snimka pre migracije gubi kasniji napredak i traži zasebnu odluku korisnika.

GitHub automatski deployment trigger nije menjan. Objava je ručno pokrenuta pomoću `redeploy --from-source`; dokumentacioni commit posle nje ne menja objavljeni runtime.
