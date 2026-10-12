# V10 — jaje kroz tri misije

`check.txt`: 181 Rails test, 6.047 tvrdnji i 16 JS testova, sve prolazi. Izolovana baza `storage/v10-full-test.sqlite3`. Novi testovi pokrivaju stvarne završetke tri misije, početni broj postojećih misija, trajnost kroz pauzu, rane i duple zahteve, nevalidna imena, reset, stare formulare i prikaz svih faza.

Browser koristi `storage/v10-browser.sqlite3` na portu 3002. Izbor stegosaura odigran je klikom; tri stvarne probne misije završene su helperom u zaštićenom `advance.rb`. Provereni su oko na 2/3, dugme na 3/3, proslava, unos Жућа i čuvanje posle reload-a. Širine 390 i 320 px; na 320 scrollWidth iznosi 320. Uzorak browser grešaka je prazan. Fizički telefon nije proveren.

`main-preservation.json` poredi sve stare kolone/redove osam tabela sa arhivom pre rada: svi identični. Jedina dopuna je nova prazna kolona egg_state. Stvarni napredak nije korišćen za probno izleganje. Arhiva je `revisions/2026-10-11-v9-before-egg/`. Glavna migracija 000900 primenjena i server restartovan; završni glavni prikaz proveren. Probni server/tab su zatvoreni, viewport vraćen.

Snimci `egg-eye-320.png`, `hatched-320.png` i `egg-preview.png` prikazuju isključivo probne podatke.
