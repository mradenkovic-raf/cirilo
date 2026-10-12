# V18 — priprema GitHub / Railway

Datum: 2026-10-12. Obuhvat je priprema i provera hosting paketa. Javni Railway servis još nije napravljen.

## Izmene

- Docker entrypoint podesi vlasnika direktorijuma baze i postojećih SQLite fajlova (DB, WAL, SHM, journal), pa koristi `gosu` da Rails/migracije rade kao UID 1000. Nema rekurzivnog menjanja vlasništva volume-a.
- `db:prepare` ostaje pri startu, posle montiranja diska. Na Railway-u nedostajući volume ili putanja van njega zaustavljaju startup.
- Production prepoznaje `APP_HOST` i `RAILWAY_PUBLIC_DOMAIN`, uz Railway healthcheck host. HTTP `/up` ne preusmerava, ne izdaje cookie i ne otvara novog učenika.
- `.dockerignore` isključuje sve `.env.*`, Rails ključeve, sadržaj `storage/`, rezerve i lokalni runtime. Bundler pri izradi koristi zaključane verzije.
- `RAILWAY.md` sadrži tačan postupak za jedan servis / jedan volume, HTTPS, stalan ključ, CI, backup i redeploy. Lokalna `.env.railway` sa slučajnim ključem ima 0600 i nije u Gitu/image-u. Nije korišćena kao probni ključ.
- Privatni GitHub repo: [mradenkovic-raf/cirilo](https://github.com/mradenkovic-raf/cirilo). Workflow `Check` ima Rails/JS/production proveru i nezavisnu Docker proveru.

## Lokalne provere

- `bin/check` nad izdvojenim bazama: **225 Rails testova / 14.391 tvrdnja, 29 JS testova**, bez grešaka. [Log](check.txt), [priprema baza](test-prepare.txt).
- Production Rails/Rack: dva browsera i dva odvojena Rails procesa, sa istim probnim ključem i bazom. Potvrđeni /up, host provera, Secure/HttpOnly/SameSite, CSRF, tuđa misija 404, zarađenih 10 XP i nastavak iste misije samo sa trajnim cookie-jem. [Log](production-check.txt), [runner](production_check.rb), [priprema](production-prepare.txt). Ovo simulira HTTPS proxy; ne predstavlja pravi TLS terminator.
- Startup odbija nedostajući ključ, nedostajući Railway volume, pogrešnu DB putanju i izlazak pomoću `..`: [rezultat](startup-check.json).
- Bash/Python/Ruby sintaksa i `git diff --check` prolaze.

## Docker i GitHub CI

Lokalni Docker servis je korisnik pokrenuo, ali proces nema dozvolu pristupa socket-u. Nisu menjane sistemske grupe niti prava socket-a. Stvarna Docker provera se zato izvršava na GitHub Actions runneru; rezultat će biti dopunjen kada run završi.

`bin/check-container` gradi image, pravi nov prazan root-owned named volume (`volume-nocopy`), proverava /up, hostove, HTTPS proxy, CSRF i cookie, zatim uklanja prvi container i otvara drugi nad istom bazom i ključem. Isti cookie mora da otvori istu sačuvanu misiju. Rails PID 1 mora biti UID 1000. Probni containeri, volume, ključevi i cookie se brišu; image ostaje. Lokalna baza se nikada ne montira. [HTTP provera](container_http_check.py).

## Granice i povratak

Sačuvani su tag `v17-stable-before-railway` (`9d21b09`) i konzistentna SQLite rezerva u `revisions/2026-10-12-v17-before-railway/`. Nema migracije podataka niti reseta igre zbog ove pripreme. Sve izvršene provere koriste zasebne baze. Privremeni kolačići Rails provere nastaju ispod projektnog `tmp/`, a Docker proba u sistemskom `/tmp`; oba se automatski uklanjaju.

Pred javni deploy ostaje kreiranje Railway servisa/volume-a, unos produkcionih promenljivih, javni domen i provera trajnosti na samom Railway-u. GitHub test nije dokaz da je to već urađeno.
