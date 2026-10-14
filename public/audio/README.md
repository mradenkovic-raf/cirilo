# Muzika igara

Numere je korisnik dostavio 2026-10-14 za pozadinsku muziku aplikacije:

- `bouncy-toy-time.mp3`: „Bouncy Toy Time”, vožnja. Izvor: `Bouncy Toy Time.mp3`.
- `strasni-mrguuud.mp3`: „Мргуд, Страшни Мргуд”, arena. Izvor: `Мргуд, Страшни Мргуд.mp3`; zamenjuje prethodnu numeru po korisnikovom izboru.

Obe su lokalni MP3, stereo, 44,1 kHz / 128 kb/s. Izvorne datoteke nisu menjane. Konverzija uklanja omot i metapodatke i smanjuje glasnoću za 4,34 dB odnosno 3,17 dB; izmerene izlazne glasnoće su -18,44 i -18,79 LUFS. Ukupno 1.432.431 bajt, približno 1,43 MB. Nova numera za arenu traje približno jedan minut i koristi verziju URL-a `v=2`.

`game_audio.js` bira numeru, dekodira je jednom po stranici u isti AudioContext koji koristi efekte i ponavlja je tokom aktivne igre. Pauza i utišavanje pamte poziciju; izlazak oslobađa audio. Efekti ostaju lokalno sintetizovani. Nema spoljnih audio servisa.

Ako se menja sadržaj MP3 datoteke, podići `?v=` u `TRACKS` u `game_audio.js`, da postojeći browseri preuzmu novu verziju.
