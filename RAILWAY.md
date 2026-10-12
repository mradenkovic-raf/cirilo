# Railway — podešavanje i objavljivanje

Objavljeno 2026-10-12 na korisnikovom trial nalogu. Kod je, na izričit zahtev korisnika, u **javnom** repozitorijumu [mradenkovic-raf/cirilo](https://github.com/mradenkovic-raf/cirilo), grana `main`. GitHub deploy verzije `614aff2` ima status `SUCCESS`. Prošli su javni HTTPS, izolacija browsera i vraćanje iste misije posle stvarnog restarta. Rezultat i granice provera vode se u [qa/v19/PROVERA.md](qa/v19/PROVERA.md).

- Javna adresa: **https://cirilo-production.up.railway.app**
- [Railway servis](https://railway.com/project/8a26bf67-82f2-47ff-8e58-86d672c1d319/service/22dc64c0-c31f-487f-978e-06d55b1bf499?environmentId=3276f7ec-16c0-45c9-92cc-63b935024066)

| Resurs | ID |
| --- | --- |
| Projekat | `8a26bf67-82f2-47ff-8e58-86d672c1d319` |
| Servis | `22dc64c0-c31f-487f-978e-06d55b1bf499` |
| Production okruženje | `3276f7ec-16c0-45c9-92cc-63b935024066` |
| Volume | `e96eab14-7c3d-4f1a-81ec-e189d9133578` |

## Postavka za trial

Aplikacija koristi jedan Rails servis i jedan trajni disk. PostgreSQL, Redis, zaseban worker i staging nisu dodati. Node služi samo za lokalne i GitHub testove.

| Podešavanje | Vrednost |
| --- | --- |
| Region | Holandija, `europe-west4-drams3a` |
| Replike | `1` |
| CPU limit | `0.5` vCPU |
| Memorijski limit | `500000000` bajtova, 500 MB |
| Volume | 500 MB, montiran na `/app/storage` |
| Uspavljivanje | Uključeno, `sleepApplication=true` |
| Restart policy | `ON_FAILURE`, najviše 3 pokušaja |
| Builder / Dockerfile | Dockerfile / `Dockerfile` |
| Build / start / pre-deploy override | Prazno |
| Healthcheck | `/up`, timeout 300 sekundi |

Uspavljivanje smanjuje rad servisa dok se aplikacija ne koristi; prvo otvaranje posle pauze može biti sporije. CPU i memorijski limiti ograničavaju resurse, a nisu novčani limit niti obećanje koliko će trial trajati. Nije uključen plaćeni plan niti su uključeni dodatni backup resursi.

## Promenljive i baza

| Promenljiva | Vrednost |
| --- | --- |
| `RAILS_ENV` | `production` |
| `DATABASE_PATH` | `/app/storage/production.sqlite3` |
| `SECRET_KEY_BASE` | Stalan tajni ključ iz lokalnog `.env.railway` |
| `ASSUME_SSL` / `FORCE_SSL` | `1` / `1` |
| `PORT` | `3000` |
| `WEB_CONCURRENCY` | `0` — jedan Puma proces |
| `RAILS_MAX_THREADS` | `3` |

`.env.railway` ima sve navedene vrednosti, dozvole 0600 i isključen je iz Gita i Docker image-a. Ključ ne menjati pri novom deployu: postojeći browser kolačići zavise od njega. `RAILWAY_ENVIRONMENT_ID`, `RAILWAY_VOLUME_MOUNT_PATH` i `RAILWAY_PUBLIC_DOMAIN` daje Railway.

Na volume-u ostaju baza i SQLite WAL/SHM fajlovi. Docker entrypoint podesi vlasništvo, pa migracije i Rails pokreće kao korisnik `rails`, UID 1000. `bin/container-start` izvršava `db:prepare` tek kada je disk montiran. Ne premeštati migracije u build ili pre-deploy komandu i ne montirati disk preko `/app`.

Produkcija počinje zasebnom bazom; lokalni napredak i rezerva ostaju na računaru. Svaki browser na javnom domenu dobija svoj napredak. Domen i `healthcheck.railway.app` aplikacija automatski dopušta; za sopstveni domen dodati `APP_HOST`, bez protokola i putanje.

## Sledeća objava

**Automatska objava pri GitHub push-u trenutno nije podešena.** Javni GitHub izvor radi, ali GitHub App pristup i deployment trigger nisu uključeni. Ne računati da push na `main` sam objavljuje aplikaciju.

Posle push-a proverene verzije na `main`, ručno povuci poslednji commit i objavi ga:

```bash
railway redeploy --from-source \
  --project 8a26bf67-82f2-47ff-8e58-86d672c1d319 \
  --environment 3276f7ec-16c0-45c9-92cc-63b935024066 \
  --service 22dc64c0-c31f-487f-978e-06d55b1bf499 \
  --yes --json
```

Ako `railway` nije u `PATH`, koristi `~/.railway/bin/railway`. Status konkretne objave proveri pre nego što je proglasiš dostupnom:

```bash
railway deployment list \
  --project 8a26bf67-82f2-47ff-8e58-86d672c1d319 \
  --environment 3276f7ec-16c0-45c9-92cc-63b935024066 \
  --service 22dc64c0-c31f-487f-978e-06d55b1bf499 \
  --limit 5 --json
```

Sačekaj `SUCCESS` za poslati deployment, zatim proveri `/up` i aplikaciju. Uspešan prijem komande ne potvrđuje da su build i pokretanje prošli. Kasnije, ako se posebno podesi GitHub autodeploy, uključiti i čekanje uspešnih CI provera (`Wait for CI`).

## Provere i čuvanje napretka

GitHub workflow `Check` proverava Rails, JavaScript, produkcijske kolačiće i Docker sa trajnom SQLite bazom. Rezultati pripreme su u [qa/v18/PROVERA.md](qa/v18/PROVERA.md). Lokalna Docker provera je `bin/check-container`; koristi privremeni disk i ne dira stvarni napredak.

Za malu HTTP proveru javne aplikacije, tek posle uspešnog deploya:

```bash
python3 qa/v19/public_http_check.py write tmp/v19-public-state.json
# Posle restarta ili sledećeg deploya:
python3 qa/v19/public_http_check.py restore tmp/v19-public-state.json
```

`write` pravi dva zasebna probna browser identiteta i jednu misiju; proverava HTTPS, CSS/JS, cookie, CSRF i odvajanje napretka. Privatni probni cookie ostaje u ignorisanom `tmp` fajlu sa dozvolama 0600. `restore` proverava istu misiju i zadatak koristeći samo stalni cookie. Ne koristiti tuđi cookie niti pokretati `write` više puta bez razloga.

**Automatski backup-i nisu uključeni.** Volume čuva napredak pri običnom restartu i deployu, ali nije zasebna rezerva. Pre buduće migracije koja briše ili menja podatke obezbediti snimak baze i sačuvati konfiguraciju sa tajnim ključem. Brisanje volume-a briše podatke; vraćanje prethodnog koda ne vraća staru bazu. Jedna instanca sa volume-om ima kratak prekid pri objavi.

## Reference

- [Rails i Dockerfile](https://docs.railway.com/guides/rails)
- [Volume i montiranje](https://docs.railway.com/volumes)
- [Volume ograničenja i backup-i](https://docs.railway.com/volumes/reference)
- [Ručno objavljivanje iz povezanog izvora](https://docs.railway.com/cli/redeploy)
- [Potrošnja i limiti](https://docs.railway.com/cli/usage)
