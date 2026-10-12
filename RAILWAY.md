# Prvi Railway deploy

Priprema: 2026-10-12. Kod je u privatnom repozitorijumu [mradenkovic-raf/cirilo](https://github.com/mradenkovic-raf/cirilo). Za objavu koristi se `main`. GitHub workflow `Check` proverava Rails, JavaScript, production kolačiće i stvarno pokretanje Docker image-a sa trajnom SQLite bazom. Rezultati pripreme su u [qa/v18/PROVERA.md](qa/v18/PROVERA.md).

Aplikacija koristi jedan Rails servis i jedan volume. PostgreSQL, Redis, Node i poseban worker nisu potrebni za njen rad. Node se koristi samo za testove.

## 1. Povezivanje repozitorijuma

U Railway dashboardu napravi projekat preko **Deploy from GitHub repo**, izaberi `mradenkovic-raf/cirilo`, granu `main` i koren repozitorijuma `/`. Railway treba da prepozna `Dockerfile`.

Ako se prvi deploy sam pokrene pre nego što postaviš promenljive i disk, može da se prekine sa jasnom porukom. To je očekivano: aplikacija odbija da na Railway-u čuva napredak u privremenom filesystemu.

## 2. Trajni disk

Dodaj **Volume**, poveži ga sa Rails servisom i postavi mount path:

```text
/app/storage
```

Servis ostaje u **jednom regionu, sa jednom instancom**. Baza je `/app/storage/production.sqlite3`. Tu se nalaze i SQLite WAL/SHM fajlovi, pa ceo direktorijum mora biti trajan. Ne montirati disk preko `/app`, jer bi sakrio kod aplikacije.

Docker entrypoint prvo podesi vlasnika direktorijuma baze i postojećih SQLite fajlova, a zatim prelazi na korisnika `rails` (UID 1000). Migracije i Puma rade kao taj korisnik. `RAILWAY_RUN_UID` ne mora da se postavlja.

## 3. Promenljive

U Variables dodaj:

| Promenljiva | Vrednost |
| --- | --- |
| `RAILS_ENV` | `production` |
| `DATABASE_PATH` | `/app/storage/production.sqlite3` |
| `SECRET_KEY_BASE` | Jedan stalni nasumični ključ |
| `ASSUME_SSL` | `1` |
| `FORCE_SSL` | `1` |

Vrednosti, uključujući nov ključ za prvi deploy, pripremljene su lokalno u **`.env.railway`**. Taj fajl ima dozvole 0600 i isključen je i iz Gita i iz Docker image-a. Njegov sadržaj možeš da uneseš u Railway Variables / Raw Editor. Nije prikazan u QA zapisima. Ne menjati ključ pri sledećem deployu: njime se otključavaju postojeći browser kolačići.

Ako se prvi deploy priprema sa drugog računara, koji nema taj lokalni fajl, nov ključ napravi samo jednom pomoću `bin/rails secret`; već korišćen ključ preuzmi iz postojećih Railway promenljivih, nemoj ga zameniti novim.

`PORT`, `RAILWAY_ENVIRONMENT_ID`, `RAILWAY_VOLUME_MOUNT_PATH` i `RAILWAY_PUBLIC_DOMAIN` daje Railway. Port se koristi automatski. Generisani javni domen i `healthcheck.railway.app` ulaze u listu dozvoljenih hostova. Za sopstveni domen postavi i `APP_HOST`, samo hostname bez `https://` i putanje.

## 4. Build, start i healthcheck

| Railway podešavanje | Vrednost |
| --- | --- |
| Builder | Dockerfile |
| Dockerfile path | `Dockerfile` |
| Build command | Prazno, koristi Dockerfile |
| Start command | Prazno, koristi `CMD ["bin/container-start"]` |
| Pre-deploy command | **Prazno** |
| Healthcheck path | `/up` |
| Healthcheck timeout | `300` sekundi |
| Restart policy | On failure, najviše 10 pokušaja |
| Replicas | `1` |

`bin/container-start` pokreće `db:prepare` pa Pumu, tek kada je volume dostupan. Ne premeštati migracije u build ili Railway pre-deploy: tamo volume nije montiran. `/up` radi i za internu HTTP proveru, bez preusmeravanja, cookie-ja ili otvaranja novog detetovog napretka.

Aktuelna Railway dokumentacija navodi da novi servisi više ne koriste stari `railway.json` / `railway.toml`. Zato ovaj projekat koristi automatski prepoznat Dockerfile i gore navedena dashboard podešavanja. Nije uveden dodatni Infrastructure as Code SDK.

## 5. Prvi javni link i provera

U Settings / Networking izaberi **Generate Domain**. Koristi stalno tu HTTPS adresu, pa primeni podešavanja i sačekaj uspešan deploy.

Proveri sledeće:

1. `/up` vraća 200, početna i slike se učitavaju.
2. Reši zadatak, zatvori i ponovo otvori isti browser na istom domenu: misija i XP ostaju.
3. Drugi browser ili telefon dobija sopstven početak; ne vidi tuđu misiju.
4. Pokreni jedan redeploy i proveri da prvi browser i dalje nastavlja isti napredak.

Javni domen ima drugi cookie od `localhost` ili kućne IP adrese, pa lokalni napredak ne prelazi automatski. Ovaj prvi deploy počinje praznom bazom. Lokalna baza i njena rezerva ostaju na računaru.

## 6. Sledeće verzije i povratak

Uključi čekanje GitHub provera (**Wait for CI**) pre Railway autodeploya. Push na `main` pokreće `Check`; Railway treba da objavi tek uspešno proverenu verziju. Za promene van produkcije koristi granu i pull request.

U Volume podešavanjima uključi automatske backup-e; pre migracije koja menja ili briše podatke napravi i ručni snimak. Volume čuva napredak pri običnom restartu/redeployu. Brisanje volume-a briše podatke, a rollback koda ne vraća automatski staru bazu. Ključ `SECRET_KEY_BASE` čuvaj uz rezervu konfiguracije. Servis sa volume-om ima kratak prekid pri deployu; healthcheck ne omogućava paralelno korišćenje istog diska.

Za lokalnu proveru Docker paketa:

```bash
bin/check-container
```

Potrebni su Docker sa pristupom pokrenutom daemon-u, Bash i Python 3. Ako Docker na računaru zahteva administratorska prava, istu skriptu možeš pokrenuti sa `sudo`. Skripta pravi potpuno nov privremeni volume, proverava dva odvojena containera sa istim cookie-jem i bazom i uklanja probne resurse. **Ne montira lokalni `storage/` niti dira stvarni napredak.** Ostaje samo image `cirilo:railway-check`.

## Izvori provereni tokom pripreme

- [Rails deploy i Dockerfile](https://docs.railway.com/guides/rails)
- [Volume, dozvole i trenutak montiranja](https://docs.railway.com/volumes)
- [Volume ograničenja i backup-i](https://docs.railway.com/volumes/reference)
- [Healthcheck i host provera](https://docs.railway.com/guides/roll-back-bad-deploy)
- [Prelazak sa starog Config as Code](https://docs.railway.com/config-as-code)
