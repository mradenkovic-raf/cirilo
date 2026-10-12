# Provera poteza štampane srpske ćirilice — 2026-10-12

Pregledano je svih 30 velikih i 30 malih oblika iz `config/alphabet.json`. Ovo je predložak za **štampana**, uspravna slova, ne za povezana pisana slova. Promenjeno je 42 od 60 skupova putanja; ostali su provereni i zadržani.

## Izvori koje smo stvarno pogledali

1. **Bukvar za prvi razred osnovne škole, Nova škola, 2018**, javno dostupan PDF: <https://www.besplatnabiblioteka.com/knjige/udzbenik-razred-1-05_opt.pdf>. Naslov i izdanje potvrđeni na prvoj strani. Strelice za svih 30 parova pogledane su na štampanim/PDF stranama **28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48 i 50**. Datoteka je sačuvana kao `stroke-sources/bukvar-public.pdf`; renderi su `public-28.png` itd. Ovaj izvor daje smer strelica, ali ne numeriše svaki potez: numeracija u aplikaciji nije predstavljena kao prepis numeracije koju izvor nema.
2. **Ivana Cmiljanović Kosovac, Bukvar — Štampana slova, Vulkan znanje, 2022**, zvanični javni pregled kompleta na sajtu Vulkan knjižara: <https://www.knjizare-vulkan.rs/files/files/pdf/377492.pdf>. U impresumu se navodi rešenje o odobrenju 650-02-00330/2022-07 od 9.12.2022. Vizuelno provereni primeri sa **brojevima i strelicama**: А/а, štampana str. **6** (PDF 21); Ш/ш, str. **54** (PDF 23); Г/г i П/п, str. **57** (PDF 26); Л/л i Љ/љ, str. **62** (PDF 31). Sačuvani `vulkan-preview.pdf` i odgovarajući PNG renderi. Preview sadrži i druge delove kompleta; pri proveri poteza korišćene su samo navedene strane sa štampanim slovima.
3. **Ivana Stojkov, „Protokoli za analizu udžbeničkih elemenata u savremenim bukvarima”, Metodička praksa 1/2017, str. 71–86**, <https://scindeks-clanci.ceon.rs/data/pdf/0354-9801/2017/0354-98011701071S.pdf>. Tekst na str. **80** objašnjava da postoje razlike u oblicima i strelicama među bukvarima i ističe doslednost, kao i uobičajeni smer odozgo nadole i sleva nadesno. Ne proglašavamo sve alternativne nastavne postupke pogrešnim.

Koordinate su naši vektorski predlošci prilagođeni tabli 100×100. U aplikaciju nisu prenete stranice, ilustracije ni fontovi iz knjiga. Izvori su korišćeni da proverimo smer, razdvajanje poteza i razliku velikog/malog oblika. Ne primenjujemo smer „uvek nadole” na zatvorene krive i kose poteze za koje izvor pokazuje suprotno, npr. dijagonalu slova И.

## Nalaz i odluke za svih 30 parova

U koloni „broj poteza” prvo je veliko, pa malo slovo. Brojevi opisuju implementirani predložak. Gde Nova škola pokazuje samo smerove, redosled je naš dosledan izbor: osnovni deo, zatim dopunske linije. Kod malog ј telo se piše pre tačke. Numerisani primeri Vulkan znanja primenjeni su direktno na А, Г, П, Л, Љ i Ш.

| Par | Izvor, str. Nova škola | Broj poteza | Provera / ispravka |
|---|---:|---:|---|
| А а | 28; Vulkan 6 | 3 / 2 | Veliko: od vrha dve zasebne kose linije nadole, zatim prečka udesno. Staro je zahtevalo polazak odozdo. Malo štampano dvostruko а ostaje; nije zamenjeno pisanim oblikom. |
| Б б | 42 | 3 / 2 | Veliko: uspravna nadole, gornja crta udesno, obli deo. Malo: rep se spušta od vrha prema ovalnom delu; oval se zatim obilazi od leve strane naniže. |
| В в | 42 | 3 / 3 | Uspravna sada ide od vrha nadole, umesto obrnuto; obli delovi idu udesno i naniže. |
| Г г | 32; Vulkan 57 | 2 / 2 | Uspravna nadole pa gornja crta udesno. Uklonjen jedinstveni potez koji je počinjao od dna. |
| Д д | 44 | 4 / 4 | Levi oslonac nadole, vrh udesno i desni oslonac nadole; donja prečka i nožice razdvojene tako da se nožica ne započinje od dna nagore. Spajanje vrha/desnog oslonca i prečke/desne nožice je naš izbor povezivanja susednih elemenata. |
| Ђ ђ | 50 | 3 / 3 | Velikom je obli završetak podignut do osnovne linije; ne pruža se ispod nje kao malo ђ. Kod malog uspravna prethodi prečki i oblom delu. |
| Е е | 36 | 4 / 1 | Veliko: uspravna nadole, sve tri vodoravne udesno; stara gornja išla je ulevo. Malo: vodoravna i obli deo su jedan povezan potez. |
| Ж ж | 46 | 5 / 5 | Središnja uspravna i četiri kraka sastaju se u istoj tački. Uklonjena stara kratka vodoravna prečka i razmak između krakova. |
| З з | 42 | 1 / 1 | Proveren smer gornjeg i donjeg luka; postojeći predložak ostaje. |
| И и | 30 | 3 / 3 | Dve uspravne nadole i zasebna dijagonala od levog dna ka desnom vrhu, kao strelica izvora. |
| Ј ј | 38 | 1 / 2 | Veliko ostaje. Kod malog: prvo telo nadole sa kukom ulevo, pa tačka; izvor ne broji tačku pa je redosled naš praktičan izbor. |
| К к | 46 | 3 / 3 | Uspravna nadole, kosa od desnog vrha ka sredini, pa od sredine ka desnom dnu. Ranije su poslednja dva dela bila spojena. |
| Л л | 44; Vulkan 62 | 3 / 3 | Levi potez od vrha naniže, vrh udesno, desna uspravna nadole. Ranije se krenulo iz donjeg levog ugla i sve spajalo u jedan potez. |
| Љ љ | 44; Vulkan 62 | 4 / 4 | Prva tri poteza kao Л, zatim obli deo od sredine udesno pa naniže. Za obli deo biran je numerisani Vulkan primer; Nova škola prikazuje suprotan smer tog dela. |
| М м | 30 | 4 / 4 | Leva uspravna nadole, unutrašnja leva kosa naniže, unutrašnja desna nagore, desna uspravna nadole. Smerovi unutrašnjeg V prate primer; razdvajanje u četiri poteza je naš izbor. |
| Н н | 40 | 3 / 3 | Obe uspravne nadole i prečka udesno već su bile odgovarajuće. |
| Њ њ | 40 | 3 / 3 | Dve uspravne nadole; vodoravna i obli nastavak spojeni su sleva nadesno u jedan potez, prema neprekinutom toku strelice na primeru. |
| О о | 34 | 1 / 1 | Smer ovala preokrenut: od vrha ulevo, nadole, oko dna i uz desnu stranu. Ranije je išao u smeru kazaljke. |
| П п | 40; Vulkan 57 | 3 / 3 | Leva uspravna nadole, vrh udesno, desna uspravna nadole. Ranije se polazilo od dna i crtalo bez podizanja. |
| Р р | 38 | 2 / 2 | Velika uspravna preokrenuta da ide nadole. Malo je već imalo odgovarajuću uspravnu i smer ovalnog dela; ostaje. |
| С с | 34 | 1 / 1 | Proveren otvoreni luk od gornje desne strane preko leve do donje desne; ostaje. |
| Т т | 32 | 2 / 2 | Gornja vodoravna udesno i uspravna nadole već odgovaraju; ostaju. |
| Ћ ћ | 50 | 3 / 3 | Veliko ostaje. Malo: uspravna prvo, prečka udesno, potom obli desni deo. |
| У у | 38 | 2 / 2 | Proverena kratka leva kosa nadole i duga desna koja završava ulevo; ostaju. |
| Ф ф | 48 | 3 / 3 | Uspravna, levi i desni obli deo razdvojeni su po prikazanim smerovima. Malo ф ima dva ovalna dela uz uspravnu, umesto jednog širokog ovalnog dela velikog Ф. |
| Х х | 46 | 2 / 2 | Obe ukrštene kose započinju na vrhu; ostaju. |
| Ц ц | 48 | 4 / 4 | Leva i desna uspravna nadole, baza udesno, kratki završetak nadole. Stari spoljašnji U imao je desnu uspravnu nagore. |
| Ч ч | 50 | 2 / 2 | Levi zaobljeni potez i desna uspravna nadole već su odgovarali; ostaju. |
| Џ џ | 48 | 4 / 4 | Dve uspravne nadole, baza udesno, srednji završetak nadole; uklonjen povratak uz desnu stranu nagore. |
| Ш ш | 36; Vulkan 54 | 4 / 4 | Tri zasebne uspravne nadole, zatim donja crta udesno, kao numerisani Vulkan primer. |

## Granica provere

Ovim je provereno šta vodič pokazuje detetu. Ocena u igri i dalje prvenstveno poredi geometrijsko poklapanje nacrtanog slova; provera izvora sama po sebi ne uvodi automatsko ocenjivanje školskog redosleda svakog dečjeg poteza. Brojevi i strelice pružaju vodič. Primenjeni redosled nije predstavljen kao jedina dopuštena varijanta rukopisa kod svih učitelja i svih bukvara.
