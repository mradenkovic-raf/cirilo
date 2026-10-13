# Android Chrome — uključivanje zvuka u igrama

Prijava korisnika: u Chrome-u na Androidu radi efekat uspešnog zadatka, ali nema muzike ni efekata u vožnji i areni.

## Uzrok i ispravka

`game_audio.js` pokušavao je da pokrene AudioContext na `pointerdown`. Za dodir/olovku aktivacija nastaje pri puštanju, a blokirani `resume()` može ostati na čekanju. Stari `resuming` flag je tada sprečavao sledeće pokušaje. FX modul zadataka nema taj flag, što objašnjava razliku u prijavljenom ponašanju.

Sada se touch/pen `pointerdown` preskače; `pointerup`, `touchend` i stvarni `click` omogućavaju pokretanje. Novi dozvoljeni gest može ponoviti zaglavljeni pokušaj; obični programski pozivi ostaju deduplikovani. Identifikator zahteva sprečava da stariji odgovor obriše stanje novijeg pokušaja. Uključivanje zvuka dugmetom takođe samo oporavlja prethodni blokirani pokušaj. Mute, skrivanje taba, pauza i Browser Back ostaju.

Pravila upoređena sa [Chrome Web Audio dokumentacijom](https://developer.chrome.com/blog/web-audio-autoplay) i [MDN user activation dokumentacijom](https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/User_activation). Ovo je konkretna greška u kodu i testiran model blokiranog browsera; ne predstavlja direktno posmatranje korisnikovog telefona.

## Regresione provere

- Četiri nova scenarija padaju protiv prethodnog koda; isti testovi prolaze sa izmenom.
- Touch/pen puštanje pokreće muziku i efekte bez preuranjenog zahteva.
- `touchend`, `click` i obična tastatura imaju rezervne putanje; prečice/modifieri i ponavljanje tastera ne pokreću muziku.
- Novi dodir oporavlja blokirani `resume()` čiji Promise nikad nije završen, dok obični programski pozivi ne umnožavaju zahteve.
- Samo uključivanje zvuka radi i pri početnom mute-u i nakon ranije blokiranog pokušaja.
- Svih 17 testova audio modula i ukupno **62 JavaScript testa** prolaze. [Lokalni izlaz](javascript-check.txt).

Nema promene melodija, glasnoće, FX zadataka, podataka ili infrastrukture. Fizički Android ostaje za korisnikovu proveru posle osvežavanja stranice.

## Javna objava

Commit `349d1de4aa86c5554f6383b3f80423045292bae2`, deployment `41580f93-5a61-42ba-bb55-af1857a8000e`, potvrđen **SUCCESS** na postojećoj adresi https://cirilo-production.up.railway.app. [Potvrda](deployment.json).

[GitHub CI](https://github.com/mradenkovic-raf/cirilo/actions/runs/38464948633) potvrđuje 298 Rails testova / 93.412 tvrdnji, 62 JS testa, production proveru i Docker sa trajnom bazom. Kratkotrajna GitHub API 502 greška prekinula je posmatranje provera, ne same provere; konačan status naknadno potvrđen kao success. [Sažetak](ci-check-summary.txt).

Read-only javni pregled preko našeg prethodnog probnog cookie-ja potvrđuje istu misiju i zadatak, HTTPS i tačan SHA sadržaja / cache verziju novih skripti, uključujući `game_audio.js`. [Izlaz](public-check.txt). Nije igrano na korisnikovom napretku i nije menjana baza, plan, konfiguracija servisa ili broj resursa.
