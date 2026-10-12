# V13 — lakši protivnik

`check.txt`: eager loading, 192 Rails testa / 6.332 tvrdnje i 26 JS testova, bez grešaka. Testna baza: `storage/v13-full-test.sqlite3`.

Novi protivnik kalibriše šansu odlučenog poteza prema početnim maksimalnim životima, tako da obična borba ima približno 75% šanse za pobedu deteta. Četvrtina razmena ostaje nerešena. Kalibracija ne koristi preostala srca niti unapred određuje pobednika. Ako oprema već prirodno daje bolju šansu, ostaje ravnomeran izbor odlučenog poteza. Moći nisu uključene u osnovnu procenu i mogu da poboljšaju ishod.

Četiri testa novog izbora koriste nezavisnu rekurzivnu računicu za proveru cilja, sve poteze i granice verovatnoće, veliki broj života i ravnomeran izbor pre aktiviranja naočara. Integracione provere potvrđuju da pomoć radi za sve tri opcije, dupli zahtev ne izvlači ponovo ishod niti daje XP, a naočare nikada ne promene sačuvan potez čak i kada bi to pomoglo detetu. Postojeće provere štita, raketa, resetovanja i konkurentnih zahteva prolaze.

`simulate.rb` koristi stvarni `BattleOpponent` uz ponovljiv izvor slučajnosti, bez upisa u bazu. Pokreće se samo u test okruženju. Rezultati 100.000 borbi bez moći nalaze se u `simulation.json`:

| Delovi | Borbe | Pobede |
|---:|---:|---:|
| 0 | 20.000 | 75,06% |
| 1 | 20.000 | 74,49% |
| 4 | 20.000 | 75,66% |
| 8 | 20.000 | 74,99% |
| 16 | 20.000 | 75,60% |

Ovo je simulacija izbora i odnosa života, ne 100.000 HTTP/Rails upisa ili odigranih dečjih borbi. Ne garantuje tri pobede u svake četiri igre. Postojeći UI nije menjan; dodatni browser pregled zato nije rađen. Glavni server na 3001 odgovara HTTP 200 nakon izmene.

`main-preservation.json` potvrđuje da su sve tabele glavne baze identične konzistentnoj arhivi `revisions/2026-10-11-v12-before-easier-arena/`. Stvarne borbe nisu korišćene za testiranje. Nema migracije ili novih zavisnosti.
