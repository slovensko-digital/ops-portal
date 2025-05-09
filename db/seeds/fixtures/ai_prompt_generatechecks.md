Your task is to check a problem reported by a person to a civil municipality servant.

The problem has a title and description (multiline in markdown) and must be checked with various rules written in Slovak.

Return all failing checks from the following checks dictionary. Optionally generate `explanation` with further guidance how to fix the problem.

- Return the check info as-is without changing any characters.
- Do NOT return any of the `Rules`.
- If the reported problem matches a check with action `back` it takes precedence over other checks.

---
## Checks dictionary

Title: Parkovanie
Info:
```
Nesprávne parkovanie sa deje v konkrétnom čase. Aby ho obec mala šancu postihnúť prostredníctvom obecnej polície, mala by sa o tom dozvedieť čo najskôr, a preto priamo.
 
Čo môže urobiť občan?
Občan môže nesprávne parkovanie nahlásiť priamo obci alebo obecnej polícii. Preposielanie podnetu cez Odkaz pre starostu by mohlo trvať pridlho.
```
More Info: /podnet-tykajuci-sa-nespravneho-parkovania
Action: back
Rules:
- Podnet nahlasuje zle zaparkované auto a nejde o vrak auta.

Title: Pitie alkoholu na verejnosti
Info: 
```
Pitie alkoholu na verejnosti sa deje v konkrétnom čase. Aby ho obec mala šancu postihnúť prostredníctvom obecnej polície, mala by sa o tom dozvedieť čo najskôr, a preto priamo.

Čo môže urobiť občan?
Občan môže pitie alkoholu na verejnosti nahlásiť priamo obecnej alebo štátnej polícii. Preposielanie podnetu cez Odkaz pre starostu by mohlo trvať pridlho.
```
More Info: /podnet-tykajuci-sa-pitia-alkoholu
Action: back
Rules:
- Podnet sa týka pitia alkoholu na verejnosti.

Title: Rušenie nočného pokoja
Info:
```
Rušenie nočného pokoja sa deje v konkrétnom čase. Aby ho obec mala šancu postihnúť prostredníctvom obecnej polície, mala by sa o tom dozvedieť čo najskôr, a preto priamo.

Čo môže urobiť občan?
Občan môže rušenie nočného pokoja nahlásiť priamo obci alebo obecnej polícii. Preposielanie podnetu cez Odkaz pre starostu by mohlo trvať pridlho.
```
More Info: /podnet-tykajuci-sa-rusenia-nocneho-pokoja
Action: back
Rules:
- Podnet sa týka rušenia nočného pokoja.

Title: Nedodržiavanie dopravných predpisov
Info: 
```
Nedodržiavanie dopravných predpisov sa deje v konkrétnom čase. Aby ho obec mala šancu postihnúť prostredníctvom obecnej polície, mala by sa o tom dozvedieť čo najskôr, a preto priamo.

Čo môže urobiť občan?
Občan môže nedodržiavanie dopravných predpisov nahlásiť priamo obci alebo obecnej polícii. Preposielanie podnetu cez Odkaz pre starostu by mohlo trvať pridlho.
```
More Info: /podnet-tykajuci-sa-dopravnych-predpisov
Action: back
Rules:
- Podnet sa týka nedodržiavania dopravných predpisov.

Title: Všeobecný lekár a jeho činnosť
Info: 
```
Povolenie na činnosť všeobecného lekára vydáva VÚC, ktorý schvaľuje ordinačné hodiny a zdravotné obvody.

Čo môže urobiť samospráva?
Obec môže lekárov a lekárky prilákať na rôzne výhody – napríklad poskytnutím priestorov či administratívnou pomocou.

Čo môže urobiť občan?
Kontaktovať svoju zdravotnú poisťovňu aj volených zástupcov vo VÚC.
```
More Info: /podnet-tykajuci-sa-vseobecneho-lekara
Action: back
Rules:
- Podnet sa týka činnosti všeobecného lekára.

Title: Čistenie potoka
Info:
```
Obec nemusí byť správcom vodného toku, respektíve potoku či rieky.

Čo môže urobiť samospráva?
Apelovať na správcu.

Čo môže urobiť občan?
Občan môže pomôcť udržiavať brehy vodných tokov čisté.
```
More Info: /podnet-tykajuci-sa-cistenia-potoka
Action: confirm
Rules:
- Podnet sa týka čistenia potoka alebo vodného toku.

Title: Schátraná budova a grafity na budove
Info:
```
Obec môže konať iba v prípade, ak je budova v jej vlastníctve alebo vo vlastníctve jej organizácie.

Čo môže urobiť samospráva?
Ak ide o súkromný majetok, môže upozorniť majiteľa či zvýšiť daň z nehnuteľností pre neudržiavanú stavbu.

Čo môže urobiť občan?
Občan si môže vyhľadať majiteľa v katastri nehnuteľností. Ak ide o pamiatkovo chránenú budovu, môže kontaktovať Pamiatkový úrad.
```
More Info: /podnet-tykajuci-sa-schratranej-budovy
Action: confirm
Rules:
- Podnet sa týka schátralej budovy alebo grafitov na budove.

Title: Výrub stromu
Info:
```
Výrub stromu na súkromnom pozemku musí schváliť príslušný orgán – obec, okresný úrad alebo ministerstvo. Realizovať sa môže iba mimo vegetačné obdobie. Ak je strom v chránenej oblasti, o výrube nerozhoduje obec.

Čo môže urobiť samospráva?
Obec je zodpovedná za údržbu, ochranu a tvorbu verejnej zelene na svojich pozemkoch. Ak ide o poškodený strom na súkromnom pozemku, môže nariadiť nevyhnutné opatrenia alebo výrub.

Čo môže urobiť občan?
Občan má rôzne možnosti, záleží však na vlastníctve pozemku. Ak žiada o výrub stromu, musí podať žiadosť na obecný úrad s príslušnými súhlasmi. V prípade nebezpečenstva ohrozenia zdravia alebo majetku je potrebné informovať obecný a okresný úrad.
```
More Info: /podnet-tykajuci-sa-vyrubu-stromu
Action: confirm
Rules:
- Podnet sa týka výrubu stromu.

Title: Zrazené divé zviera
Info:
```
Obec je zodpovedná za odstránenie zrazených zvierat v intraviláne, zatiaľ čo v extraviláne je zodpovedný správca ciest. Odstránenie môže byť oneskorené kvôli nedostatku pohotovostnej služby.

Čo môže urobiť samospráva?
Obec je povinná neodkladne odstrániť zrazené zviera na jej území. Môže tiež požiadať správcu cesty o odstránenie zvieraťa mimo obce.

Čo môže urobiť občan?
Zrazené zviera je potrebné okamžite nahlásiť obci alebo správcovi ciest. V prípade zrážky s vlastnou zverou treba kontaktovať políciu.
```
More Info: /podnet-tykajuci-sa-zrazeneho-zvierata
Action: confirm
Rules:
- Podnet sa týka zrazeného divého zvieraťa.

Title: Oprava cesty v obci
Info:
```
Nie každá cesta, ktorá sa nachádza v obci, je považovaná za miestnu cestu, ktorá je v jej vlastníctve a správe.

Čo môže urobiť samospráva?
V závislosti od správcu danej komunikácie môže samospráva daný úsek opraviť alebo kontaktovať zodpovedný subjekt.

Čo môže urobiť občan?
Občan môže nahlásiť stav cesty jej správcovi. Typ a teda aj správcu cesty zistí na Mape cestnej siete.
```
More Info: /podnet-tykajuci-sa-opravy-cesty
Action: confirm
Rules:
- Podnet sa týka opravy cesty v obci.

Title: Zmena značenia dopravy
Info:
```
Nie každá cesta, ktorá sa nachádza v obci, je považovaná za miestnu cestu, na ktorej môže obec rozhodovať o použití dopravných značiek.

Čo môže urobiť samospráva?
Ak obec zistí, že dopravná značka je poškodená, má povinnosť to riešiť. Pri značkách na cestách v jej správe potrebuje na opravu súhlas dopravného inšpektorátu.

Čo môže urobiť občan?
Občan môže nahlásiť poškodenú dopravnú značku správcovi cesty. Typ a teda aj správcu cesty zistí na Mape cestnej siete.
```
More Info: /podnet-tykajuci-sa-dopravneho-znacenia
Action: confirm
Rules:
- Podnet sa týka zmeny alebo opravy dopravného značenia.

Title: Nelegálna skládka
Info:
```
Obec pri odstraňovaní nelegálneho odpadu spolupracuje s príslušným okresným úradom, ktorý zisťuje pôvodcu odpadu, aby mu ho dal odstrániť na jeho náklady.

Čo môže urobiť samospráva?
Ak obec zistí, že sa na jej území nachádza nelegálna skládka, oznámi to príslušnému okresnému úradu.

Čo môže urobiť občan?
Občan môže nahlásiť nelegálnu skládku obci alebo príslušnému okresnému úradu.
```
More Info: /podnet-tykajuci-sa-nelegalnej-skladky
Action: confirm
Rules:
- Podnet sa týka nelegálnej skládky odpadu.

Title: Vrak
Info: Odstránenie vraku je komplikovaný proces a môže trvať dlhšie.
Action: confirm
Rules:
- Podnet nahlasuje vrak vozidla a nie iba zle zaparkované auto.

Title: Vulgarizmy
Info: Podnet obsahuje vulgarizmy alebo je napísaný nevhodne.
Action: back
Rules:
- Podnet, ktorý obsahuje vulgarizmy sa neakceptuje.