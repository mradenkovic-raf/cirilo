# Ћирило roadmapa razvoja

Sačuvano po dogovoru 11. oktobra 2026. Polazna verzija je v5. Sledeći razvoj treba da pomogne detetu da samostalno razume zadatak, čita sa razumevanjem i pamti slova kroz smislenu avanturu.

Zvučni vodič je odložen na korisnikov zahtev zbog mogućeg troška i povezivanja sa dodatnim servisom. Ostale četiri stavke su isporučene u v6; konačan obim i provere zabeleženi su u [STANJE.md](STANJE.md) i [qa/v6/PROVERA.md](qa/v6/PROVERA.md).

V8 je dodatni prolaz kroz dečji UX: jedna glavna radnja po ekranu, manje ponovljenog teksta i detalji na dodir. Provere su u [qa/v8/PROVERA.md](qa/v8/PROVERA.md); zvučni vodič i dalje čeka.

V9 dodaje izbor naziva slike, popravku jednog pogrešnog slova i spajanje tri para. Igre se smenjuju kroz misije, bez smanjivanja vežbi pisanja i bez dužih misija. Sačuvan je mirniji v8 raspored; zvučni vodič ostaje odložen.

## Prioritet čitanja — dogovor 12. oktobra 2026.

Korisnik je postavio čitanje i snalaženje sa slovima kao glavni cilj; praćenje oblika i pisanje su dopuna. Isporučeno u v16: svaka nova misija ima 10 čitalačkih zadataka i 2 pisanja. Posle greške dodatno se vežba čitanje, bez dodavanja novih crteža. Ostaju 12 redovnih koraka, 145 XP i postojeće nagrade. Započete stare misije zadržavaju sadržaj. Detalji i provere su u [qa/v16/PROVERA.md](qa/v16/PROVERA.md).

U v17 je po novom zahtevu prošireno čitanje prostornih odnosa: **u, na, pored, ispred, iza**, uz 20 kombinacija jabuke/lopte i ranca/kutije. Nova misija ima dve kratke priče umesto jedne: prostorni zadatak i jedan iz postojeće grupe o veličini, mestu ili radnji. Ostaje 12 redovnih zadataka, odnos 10/2 i 145 XP. [Provere v17](qa/v17/PROVERA.md).

Sledeće ideje su **predlozi, još nisu ugrađene niti odobren redosled implementacije**:

1. **Slogovi koji postaju reč.** Dete spaja `СО` + `ВА` ili `РИ` + `БА`, pa bira sliku cele reči. Početni nivo ima dva sloga i malo ponuđenih delova; kasnije dodajemo višak i tri sloga. Delovi nemaju boje, oblik spojnica ili stalne položaje koji odaju redosled. Samo slaganje ne završava zadatak: izbor slike proverava značenje. Ovo je prvi preporučeni dodatak.
2. **Jedno slovo menja značenje.** Prvo `СОК`, zatim `СКОК`: dete svaki put čita i bira odgovarajuću sliku. Druga slika i raspored odgovora se menjaju, da uspeh ne bude ponavljanje istog klika. Birati kratke stvarne reči koje se mogu jasno ilustrovati.
3. **Koja rečenica opisuje sliku?** Uz sliku psa koji juri mačku stoje `Пас јури мачку.` i `Мачка јури пса.`, plus odgovori sa drugom radnjom. Isti likovi i slične reči traže čitanje celog iskaza, ne prepoznavanje prve imenice. Početi kraćim iskazima, pa uvoditi ovakve razlike.
4. **Dve rečenice, jedan mali problem.** `Мила има лопту. Лопта је у ранцу.` → dete bira gde je lopta. Tekst ostaje vidljiv, pa proveravamo razumevanje i dopuštamo ponovno čitanje. Kasnije se mogu birati radnje u maloj sceni, uz postepeno povećanje dužine.

Ove igre mogu da rade bez novog glasovnog servisa. Audio vodič ostaje odložen. Pedagoški smer je povezivanje slova i delova reči sa celom rečju, a zatim razumevanje povezanih rečenica, što preporučuje [IES/WWC vodič za početno čitanje](https://ies.ed.gov/ncee/wwc/practiceguide/21). Konkretne igre i srpski primeri iznad naš su predlog za ovu aplikaciju; vodič se odnosi na nastavu na engleskom i ne potvrđuje učinak naše aplikacije.

## Redosled razvoja

1. **Zvučni vodič.** Isti srpski glas na svim uređajima, kratka uputstva, reakcije i izgovor reči posle uspešnog čitanja. Detaljan predlog ispod.
2. **Zadaci u maloj priči.** Primeri: „Стави јабуку у ранац” i „Узми малу лопту”. Dete izvršava ono što pročita. Ponuđene slike traže razlikovanje i predmeta i osobine, tako da prepoznavanje samo jedne reči nije dovoljno. Uputstvo može da se čuje; rečenica čije se razumevanje proverava ostaje za samostalno čitanje.
3. **Vežbe prema konkretnim zabunama.** Nadograditi postojeće vraćanje slabijih slova praćenjem onoga što dete zaista meša, na primer П i Р. Uvoditi kratka poređenja i vraćati tu razliku kroz različite reči i zadatke. Vođena vežba ostaje odvojena od samostalnog uspeha.
4. **Mapa avanture.** Šuma, pećina, vulkan i svemir daju misijama povezan cilj: stići do protivnika ili spasiti dinosaurusa. Napredak prati završene misije; kupljene teme aplikacije ostaju zasebni kozmetički izbori.
5. **Posebne moći opreme u areni.** Razraditi naočare koje jednom otkriju protivnikov potez, štit koji jednom zaustavi udarac i rakete za izbegavanje. Pre uvođenja odrediti ograničenja i odnos prema postojećim dodatnim životima. Bitka i dalje služi kao nagrada posle učenja.

Isporučeno u v6: 12 priča u tri grupe, beleženje konkretnih zamena i vraćanje parova do uspeha u dve različite misije, četiri sveta sa ukupno 16 koraka i četiri spasena druga, tri moći sa jednom upotrebom po borbi. Štit čeka prvi dolazeći pogodak; rakete preskaču jednu rundu bez napada i oštećenja. Vodič ostaje za kasnije; postojeći zvučni efekti i opcioni izgovor preko glasa uređaja ostaju dostupni.

## Predlog zvučnog vodiča

### Glas i priprema snimaka

Klik dobija jedan jasan, topao i vedar srpski glas. Izgovor slova i reči ostaje čist, bez efekata koji otežavaju razlikovanje glasova. Replike su kratke i konkretne.

Unapred pripremiti audio-fajlove i isporučivati ih sa Rails aplikacijom. Govor se ne generiše tokom detetove igre. Tako izgovor ne zavisi od instaliranog srpskog glasa, nema poziva servisu za svaki zadatak, a isti snimak može da se koristi više puta. Postojeći Web Speech trenutno zavisi od srpskog glasa na uređaju.

Prvi kandidat za probne snimke je Azure Speech, koji navodi srpske ćirilične glasove `sr-RS-NicholasNeural` i `sr-RS-SophieNeural`. Glas i servis nisu konačno odabrani; prvo preslušati kratak uzorak uputstava, reči i slova. Posebno proveriti Љ, Њ, Ђ, Ћ, Џ i Ж, naglasak i da li izolovano slovo dobija neželjen naziv ili dodatni samoglasnik. Slabe snimke zameniti boljom sintezom ili ljudskim snimkom. [Microsoft dokumentacija](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts)

Za generisanje je potreban pristup izabranom servisu. Eventualni trošak nastaje pri pripremi i izmeni snimaka; aplikacija u radu samo reprodukuje sačuvane fajlove. Alternativa su ljudski snimci uz potpuno isti način povezivanja sa igrom.

### Kada vodič govori

| Trenutak | Primer i pravilo |
| --- | --- |
| Novi zadatak | „Прочитај реч, па додирни њену слику.” Objašnjava radnju, ne izgovara odgovor. |
| Pisanje cele reči | „Препиши реч. Заврши свако слово, па провери.” |
| Dopuna | „Изабери слово које недостаје, па га напиши.” Ne imenuje nedostajuće slovo. |
| Pamćenje | Dok je reč vidljiva: „Погледај и запамти реч.” Kada je sakrivena: „Сложи реч по сећању.” Ne izgovara ciljnu reč ni pri ponavljanju uputstva. |
| Tačan odgovor | Kratka pohvala, pa slika i izgovor završene reči i rečenice o značenju, npr. „Сат. Сат показује време.” |
| Greška | „Погледај још једном.” ili „Хајде кратко да поновимо.” Bez otkrivanja odgovora. |
| Slovarica | Na zahtev izgovara slovo i primer reči. Ovo je upoznavanje sa slovom, bez ocene samostalnog čitanja. |
| Misija, radionica i arena | Kratko objašnjenje radnje ili osvojenog predmeta, uz postojeće vizuelne reakcije. |

Ponavljanje zvučnog uputstva je dozvoljeno i ne otkriva rešenje. Igra ne sme da traži slušanje cele replike pre nego što dete može da radi. Ne ponavljati pohvalu posle svakog pojedinačnog poteza olovke.

### Ugradnja i kontrola

- MP3 snimci u `public/audio/sr/`, sa spiskom ključeva, tačnih tekstova i fajlova. Rails bira dozvoljeni audio-ključ prema tipu zadatka i njegovom trenutnom stanju.
- Mali JavaScript audio-modul: jedan govor u jednom trenutku, prekid prethodne replike pri promeni zadatka, utišavanje efekata dok vodič govori i poštovanje isključenog zvuka.
- Vidljivo dugme „Чуј упутство” ponavlja samo trenutno dozvoljeno uputstvo. Razdvojiti podešavanje govora i efekata, uz opšte isključenje svih zvukova.
- Pokretanje zvuka vezati za stvarni dodir ili klik. Posle prelaska na drugi ekran proveriti da li je reprodukcija uspela; ako browser blokira automatski zvuk, ponuditi dugme za puštanje. Jedan početni klik ne smatramo garancijom za sve naredne stranice. [Pravila automatske reprodukcije](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Autoplay)
- Nedostupan ili spor snimak ne blokira zadatak. Tekst i slike ostaju dostupni. Lokalni audio-fajlovi sami po sebi ne uvode offline rad misija.

### Prva isporuka i provera

Pripremiti mali probni paket: nekoliko uputstava, tačan i pogrešan odgovor, primer značenja reči i zahtevna slova. Odabrati glas prema preslušavanju pre generisanja pune banke. Zatim pokriti postojeće tipove zadataka, slovaricu i prikaze značenja; reakcije radionice, prodavnice i arene dodavati u istom glasu.

Proveriti da zadaci čitanja, dopune i pamćenja ne otkrivaju odgovor zvukom, uključujući ponavljanje uputstva, osvežavanje i promenu faze. Proveriti mute, prekid prethodnog govora, brze uzastopne klikove, sporo učitavanje i nastavak igre bez zvuka. Reprodukciju i povratak iz pozadine proveriti na fizičkom Androidu i iPhoneu uz desktop browser. Konačan kvalitet vodiča procenjujemo i po tome može li dete samostalno da započne zadatak.
