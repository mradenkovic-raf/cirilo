# Muzika igara

Numere je korisnik dostavio 2026-10-14 za pozadinsku muziku aplikacije:

- `bouncy-toy-time.mp3`: „Bouncy Toy Time”, vožnja. Izvor: `Bouncy Toy Time.mp3`.
- `strasni-mrguuud.mp3`: „Strašni Mrguuuud”, arena. Izvor: `Strašni mrguuuuud(1).wav`.

Obe su lokalni MP3, stereo, 44,1 kHz / 128 kb/s. Izvorne datoteke nisu menjane. Konverzija uklanja omot i metapodatke i smanjuje glasnoću za 4,34 dB odnosno 4,52 dB; izmerene izlazne glasnoće su približno -18,4 LUFS za obe. Ukupno 826.809 bajtova, približno 0,83 MB.

`game_audio.js` bira numeru, dekodira je jednom po stranici u isti AudioContext koji koristi efekte i ponavlja je tokom aktivne igre. Pauza i utišavanje pamte poziciju; izlazak oslobađa audio. Efekti ostaju lokalno sintetizovani. Nema spoljnih audio servisa.

Ako se menja sadržaj MP3 datoteke, podići `?v=` u `TRACKS` u `game_audio.js`, da postojeći browseri preuzmu novu verziju.
