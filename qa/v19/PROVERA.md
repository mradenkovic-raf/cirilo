# V19 — javni Railway deploy

Datum: 2026-10-12. Kod aplikacije nije menjan; objavljena je verzija `614aff2ed71e9938f0d8f3ad4f3bcd53f8536687`, čiji Rails/JS/Docker nalazi ostaju u [v18](../v18/PROVERA.md).

## Rezultat

- Aplikacija: https://cirilo-production.up.railway.app
- GitHub: https://github.com/mradenkovic-raf/cirilo — korisnik je izričito tražio promenu na `PUBLIC`.
- GitHub deploy `a28039c8-0238-4305-9498-8c95ea1f7d2b`: `SUCCESS`, potvrđeno i posle kontrolisanog restarta. [Statusi](deployments.json).
- Raniji CLI deploy `b6bc18e3-b0be-4fc3-a2da-72d353b02d0d` zaustavljen je kao dupli build; završio je kao `REMOVED`, nije proglašen uspešnim.
- Javni GitHub izvor je povezan na `main`. Upit za deployment triggers vratio je praznu listu; automatska objava push-a nije podešena. Sledeća objava radi se ručno, posle provera.

## Javna provera

[Skripta](public_http_check.py) koristi pravi HTTPS uz proveru sertifikata, bez spoofovanja Host/proxy zaglavlja. [Prvi rezultat](public-http.txt) potvrđuje `/up` bez kolačića, početnu, CSS/JS, Secure/HttpOnly/SameSite=Lax trajni cookie, kreiranje misije sa pravim CSRF tokenom, 404 za tuđu misiju i 422 za upis bez CSRF-a.

Probna misija i identitet sačuvani su pre `railway restart`. Novi Puma proces je pokrenut bez ponovne izgradnje image-a; [izvod runtime zapisa](restart-runtime.json). [Vraćanje posle restarta](public-restore.txt) potvrđuje isti zadatak i poziciju samo preko trajnog cookie-ja. Provera nije menjala postojeći dečji napredak: otvorena su dva zasebna HTTP identiteta. Probni cookie je isključivo u ignorisanom lokalnom `tmp/v19-public-state.json`, sa dozvolama 0600; nije u dokazima ni Gitu.

Stvarni ugrađeni browser otvorio je javnu početnu i prikazao dinosaurusa, cilj spasavanja i dugme za igru. Vizuelni pregled nije našao polomljene resurse; browser nije prijavio JS upozorenja/greške. Taj browser nije rešavao misije. Lokalna development baza nije korišćena za ove provere.

## Trial resursi

[Sačuvana konfiguracija bez promenljivih](service-config.json): jedan servis i jedna replika u `europe-west4-drams3a`, 0,5 vCPU, `memoryBytes=500000000`, uspavljivanje uključeno i najviše tri ponovna pokretanja pri grešci. Volume je 500 MB na `/app/storage`. Tajni ključ nije ispisivan niti dodat Gitu; `.env.railway` ostaje 0600 i izuzet iz image-a.

[Metrike](metrics.json) pri završnoj proveri pokazuju približno 91 MB trenutne memorije, maksimum oko 127 MB u posmatranih deset minuta, i CPU maksimum oko 0,077 vCPU. To nije test opterećenja ni garantovana buduća potrošnja. Railway limit memorije u metrikama prikazuje približno 512 MB, dok konfiguracija sadrži 500.000.000 bajtova.

Trial status i potrošnja provereni su kroz CLI. Podaci o nalogu, billing metapodaci i obračun čuvaju se samo lokalno u ignorisanom `tmp`, sa dozvolama 0600; nisu deo javne evidencije. Plan i novčani limiti nisu menjani. Nema dodatnih servisa, posebnog worker-a ili zasebne baze.

## Granice

Automatski backup-i nisu uključeni. Volume čuva bazu pri restartu/redeployu, ali nije odvojena rezerva. Čitav ciklus automatskog uspavljivanja/buđenja nije čekan; podešavanje je pročitano nazad. Nisu izvođeni test opterećenja, cela misija/arena na javnom serveru, niti fizički Android/iPhone pregled. Nova QA skripta prošla je Python sintaksu; `git diff --check` prolazi. Nisu ponavljani svi prethodni testovi jer aplikacioni kod nije menjan.
