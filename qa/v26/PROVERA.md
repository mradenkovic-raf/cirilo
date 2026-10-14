# V26 — korisnikova muzika za igre

Datum: 2026-10-14. Lokalna izmena, bez objave na Railway. Produkcija ostaje v25.

Prva provera ispod odnosi se na „Bouncy Toy Time” i prethodnu numeru arene „Strašni Mrguuuud”. Obe numere dolaze iz datoteka koje je korisnik dostavio. MP3 kopije zajedno imaju 826.809 bajtova; izvorne datoteke nisu menjane. Izlazna glasnoća izmerena ffmpeg loudnorm analizom: -18,44 i -18,42 LUFS. Efekti koriste prethodnu glasnoću; muzika ima zasebnu granu u istom AudioContext-u.

## Provere

- Svih sedam JS test datoteka prolazi: [javascript-check.txt](javascript-check.txt). Audio ima **23 testa**, uključujući stare regresije Android dodira i blokiranog resume: [game-audio-check.txt](game-audio-check.txt).
- Izbor odgovarajuće lokalne numere, jedno preuzimanje/dekodiranje po stranici, jedan muzički tok, nastavak pozicije posle pauze i utišavanja, petlja bez tajmera, nezavisni efekti, Browser Back i skriven tab.
- Odloženi download/decode ne pušta muziku posle završetka, utišavanja, skrivanja ili izlaska. Greška učitavanja/dekodiranja ne ometa igru i efekte; novi stvarni gest može ponoviti pokušaj. Izlazak otkazuje aktivno preuzimanje.
- Rails provera odvojenosti uređaja: **10 testova / 175 tvrdnji**, bez neuspeha: [rails-check.txt](rails-check.txt). Nema Ruby izmena ni migracija; kompletan Rails paket nije ponovo pokretan za ovu audio izmenu.
- HTTP pregled potvrđuje 200, `audio/mpeg`, isti SHA-256 kao lokalne datoteke i odsustvo Set-Cookie za oba snimka: [audio-http-check.json](audio-http-check.json).
- Stvarni in-app browser: vožnja pokrenuta i završena porazom; arena otvorena, odigran uspešan udarac, zvuk isključen i ponovo uključen. Bez JS grešaka/upozorenja tokom ovih tokova. Ova provera potvrđuje tok igre i kontrole, ne slušni kvalitet zvuka. Fizički Android/iPhone nisu provereni.

Korišćene su isključivo baze `storage/v26-test.sqlite3` i `storage/v26-browser.sqlite3`, sa namenski pripremljenim prečicama do vožnje i arene. Glavna baza nije menjana. Probni server na 3026 zaustavljen je posle pregleda.

## Zamena numere arene — 2026-10-14

Korisnik je naknadno izabrao `Мргуд, Страшни Мргуд.mp3`. Zamenjen je samo sadržaj MP3 fajla arene; njegov URL sada koristi `v=2` da browser ne zadrži staru pesmu. Vožnja i audio logika ostaju isti. Nova numera traje približno 59,6 s, izlaz je stereo MP3 44,1 kHz / 128 kb/s, 954.243 bajta i -18,79 LUFS posle smanjenja za 3,17 dB. Ukupna veličina muzike je 1.432.431 bajt. Izvorni fajl ostao je neizmenjen.

Ponovljena 23 postojeća audio testa prolaze; [game-audio-check.txt](game-audio-check.txt) je osvežen. Rails static middleware vraća novu verziju sa statusom 200, tipom `audio/mpeg` i identičnim SHA-256: [arena-replacement-check.json](arena-replacement-check.json). Raniji HTTP zapis odnosi se na prethodnu numeru. Browser/telefoni nisu ponovo proveravani za ovu zamenu snimka. Još nije objavljeno.
