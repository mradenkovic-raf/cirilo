# V16 — čitanje je glavni deo misije

Datum: 2026-10-12. Korisnik je zatražio da pisanje i praćenje oblika budu sekundarni, a da u jednoj misiji preovladaju čitanje i rad sa slovima.

## Isporučena promena

Nova misija ima **10 čitalačkih zadataka i 2 zadatka pisanja**, ukupno 12 koraka i 145 XP. Sadrži po dva čitanja reči uz izbor slike i izbora naziva slike, a po jedan zadatak sastavljanja reči, popravke slova, spajanja reči sa slikama, dopune rečenice, pamćenja reči i razumevanja kratke priče. Pisanje jednog slova je na četvrtom koraku. Deseti korak smenjuje pisanje cele reči i dopisivanje slova kroz naredne misije.

Svako ciljno slovo ima četiri zadatka i najmanje tri čitalačka. Prvo slovo dobija i samostalno sastavljanje reči, tako da prioritetna zabuna, npr. П/Р, ostaje zastupljena u odgovorima koji se mogu pratiti. Geometrijska procena pisanja i pravila pamćenja slova nisu menjani.

Prva greška u v6 zadatku ubacuje poslednji završeni čitalački zadatak, preskačući ranija pisanja. Ako ga još nema, generiše se čitanje reči za trenutno slovo uz četiri slike. Ponuda se ponovo raspoređuje; originalni zadatak ostaje isti. Ova ponavljanja ne donose XP niti samostalan napredak pamćenja, a i dalje ih ima najviše tri po misiji. Ukupan broj zadataka može da bude 15, ali pisanja ostaju samo dva.

Format novih zadataka je 6. Započete misije formata 3/4/5/6 čuvaju svoj raspored, identifikatore, odgovore, cursor, XP i stanje sakrivene reči. V3–V5 zadržavaju i raniji način ponavljanja. Promena odnosa važi od sledeće nove misije; nema resetovanja ili preuređivanja aktivne igre. Nema migracije baze.

## Provere

- **220 Rails testova, 12.930 tvrdnji**, seed 4332, bez grešaka na `storage/v16-tests.sqlite3`. [Sažetak izvršavanja](rails-tests.txt). Dodato pet testova; postojeće provere protokola prilagođene su tako da same izaberu tip zadatka koji proveravaju, umesto da zavise od njegovog mesta u misiji.
- Pokriveno: odnos 10/2 u šest uzastopnih misija, oba tipa preostalog pisanja, sva tri ciljna slova, 145 XP u obe varijante, očuvanje sačuvanih V3–V5, čitanje posle greške pre i posle pisanja, najviše tri ponavljanja, izostanak dodatnog XP-a i napretka pamćenja.
- Postojeća provera konkretnih zamena slova otkrila je da bi prvobitno preuređivanje izostavilo samostalno slaganje za prioritetno slovo. Mesta ciljnih slova u sastavljanju i dopuni rečenice zamenjena su; provera ostaje i sada prolazi.
- **29 JavaScript testova** prolazi, [zapis](javascript-tests.txt); [eager loading](eager-load.txt) i `git diff --check` prolaze.
- Stvarni browser, izdvojena `localhost:3002` baza: prva misija otvara „Прочитај реч. Изабери слику.”, АУТО i četiri slike. Namerno pogrešan odgovor otvara čitalačko ponavljanje i produžava put 12→13. Tačno ponavljanje daje 0 XP i vraća originalne izbore; originalni zadatak zatim daje 10 XP. Sledeći zadatak je izbor naziva sa slike. [Snimak novog početka](reading-start.png).
- Na glavnom serveru `127.0.0.1:3001` potvrđen je novi roditeljski opis 10/2. Nisu odigrani zadaci niti menjane postojeće igre. Sve ranije tabele glavne baze identične su rezervnoj kopiji pre rada: [poređenje](main-preservation.json).

Probni server 3002 je zaustavljen. Nije ponavljan fizički test Androida/iPhone-a: prikazi i kontrole zadataka ostaju postojeći. Izvodi testa pripadaju ovoj verziji; nisu dokaz da je dete lakše savladalo čitanje. Korisnikov pregled i proba sa detetom tek slede.

## Sačuvana prethodna verzija

Pre izmene radni direktorijum bio je čist. Git tag `v15-stable-before-reading-priority` pokazuje na `b9c1ede`; nove izmene su na grani `reading-priority`. Konzistentna baza pre rada je `revisions/2026-10-12-v15-before-reading-priority/development.sqlite3`. Rezervna baza i browser snimak nisu u Gitu. Tokom provera Bundler automatski koristi privremene foldere u `/tmp`, dok su trajni nalazi u ovom folderu.

Predlozi novih igara (slogovi, slične reči, izbor rečenice i mini-priče) zabeleženi su odvojeno u [ROADMAP.md](../../ROADMAP.md). To su predlozi za naredni korak, ne dodatne igre isporučene u v16.
