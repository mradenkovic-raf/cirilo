# Provera v6

11. oktobar 2026. V6 dodaje čitanje sa razumevanjem, vraćanje konkretnih zamena slova, mapu avanture i tri posebne moći opreme. Novi glas nije uveden, niti je povezan plaćeni servis.

## Automatske provere

- `automatske-provere.txt`: 138 Rails testova, 2.854 tvrdnje, bez neuspeha/grešaka/preskakanja; eager-load i 10 JavaScript provera geometrije prolaze. Baza `storage/v6-full-test.sqlite3`.
- `practice-controls.txt`: pet dodatnih provera ponašanja pisanja prolazi, koristeći `qa/v5/practice-controls.mjs`.
- `learning-provera.txt`: ciljane learning provere, 49 testova / 1.717 tvrdnji na `storage/v6-learning-test.sqlite3`.
- Ciljane provere mape: 10 testova / 238 tvrdnji na `storage/v6-adventure-test.sqlite3`. Obuhvataju granice 0–32, postojeći napredak, spasavanja, nastavak i oba reseta.
- Ciljane provere arene: 32 testa / 358 tvrdnji na `storage/v6-battle-test.sqlite3`. Obuhvataju stare borbe, snapshot opreme, sve tri moći i konkurentne/stare/ponovljene zahteve.

Prva puna provera naletela je na zastareo v5 `db/schema.rb`; nakon izrade kompletnog schema fajla ostao je jedan stari test koji je očekivao značenje reči za novu priču. Test sada zasebno potvrđuje odsustvo značenja reči za priču i prisustvo za sve prave reči. Završni rezultat iznad je potpun prolaz.

## Production i nadogradnja

`production_check.rb` pravi isključivo novu `storage/v6-production.sqlite3`. `production-check.txt` potvrđuje svih osam migracija, HTTP/CSRF tok 12 zadataka, tačno 145 XP i odsustvo ponovne nagrade, mapu i arenu sa sve tri moći, sačuvan otkriven potez, odbijen zastareo zahtev, blokiran udarac i neutralnu raketnu rundu. Provereno je i 14 direktno uključenih CSS/JS resursa. To je Rails/Rack provera, bez javnog servera i stvarnog pisanja.

`upgrade_check.rb` koristi isključivo kopiju sačuvane v5 baze u `storage/v6-upgrade.sqlite3`. `upgrade-check.txt` potvrđuje da su posle migracija sačuvani svi originalni redovi i kolone sedam tabela, kao i započeta v3 misija sa istim ID-jevima, cursorom i stanjem memorije.

Pre primene na glavnu bazu napravljen je još jedan konzistentan backup: `revisions/2026-10-11-v5-before-adventure/development-before-v6-apply.sqlite3`. Migracije 000700 i 000800 su primenjene. `main-preservation.txt` potvrđuje da su svi prethodni podaci glavne baze ostali isti: 185 XP, potrošeno 0, devet završenih misija. `main-before.json` čuva podatke za lokalno poređenje; nijedan stvarni pokušaj, kupovina, reset ili borbeni potez nije izveden tokom QA.

## Browser provera

Lokalni probni server na portu 3002 koristi samo `storage/v6-browser.sqlite3`. `prepare.rb` odbija drugi put baze. Početnih 12 misija / 1.740 XP / 12 delova pripremljeno je sintetičkim validnim odgovorima preko servisa. Nisu ručno odigrane cele misije.

- Mapa na 1280 i 320 px: četiri sveta, 12/16 koraka i 3/4 spasena druga. Širina sadržaja na 320 px je 305 px. Završni glavni prikaz zasebno pokazuje stvarnih 9/16, dva druga i nastavak sa 4/12 zadataka; stanje je samo čitano.
- Arena na 320 px: naočare su otkrile Varku i zadržale je posle osvežavanja; zatim je uključen svetlosni štit i namerno izabran slabiji redovan Štit. Pogodak je blokiran i ostalo je 3 srca + 12 delova. Rakete su preskočile sledeću rundu, obe strane bez gubitka. Sve tri posebne kontrole postale su iskorišćene. Širina sadržaja 320 px i bez JS grešaka.
- Priča u misiji 13: „Узми малу лопту.” Namerno odabrana mala jabuka daje grešku i 13 koraka; wallet ostaje 1.820. Malo а zatim je nacrtano kroz browser, ocenjen oblik 100, uz 0 XP. Povratak na istu priču i izbor male lopte daju 10 XP, wallet 1.830.
- Priča u misiji 14: „Пронађи јабуку у ранцу.” Četiri slike jasno razlikuju jabuku/loptu i ranac/kutiju. Ručni tačan izbor daje 10 XP, sa 1.965 na 1.975.
- Priča u misiji 15: „Покажи мачку која спава.” Prikaz razlikuje mačku/psa i spavanje/trčanje. Ručni tačan izbor daje 10 XP, sa 2.110 na 2.120. Pregledana na telefonu i računaru.
- Između tih priča `prepare.rb` sintetički rešava ostale zadatke. Dva namerna izbora Ф umesto И u dopuni poslata su kroz isti servis radi provere roditeljskog prikaza; nisu izvedena rukom. Prikaz beleži odgovarajući par, a planer vraća njega u buduću misiju.
- U misiji 16 pregledan je stvarni prikaz poređenja и/ф iz tog para. Na 320 px sadržaj ostaje 320 px, bez JS grešaka. Roditeljska tabela prikazuje dve zamene И → Ф i 0/2 samostalna uspeha; širina sadržaja je 305 px na ekranu od 320 px.

Snimci: `main-map-desktop.png`, `map-desktop.png`, `map-320.png`, `story-size-320.png`, `story-place-320.png`, `story-action-320.png`, `story-action-desktop.png`, `battle-powers-320.png`, `confusion-practice-320.png`, `confusions-parent-320.png`. Probni snimci prikazuju probni wallet; samo `main-map-desktop.png` prikazuje stvarni napredak. Probni server je po proverama ugašen; glavna aplikacija ostaje na portu 3000.

## Granice

Provera uskog prozora u Chromiumu nije fizički Android ili iPhone. Nisu provereni olovka, Docker, javni hosting ili novi govorni servis. Procena pisanja ostaje geometrijska pomoć; dva samostalna uspeha smanjuju prioritet zabune, ne dokazuju trajno naučeno slovo. Banka priča ima 12 rečenica, a mapa 16 koraka; posle toga se postojeće učenje, oprema i arena nastavljaju bez ponovnog spasavanja ili novog XP bonusa za mapu.
