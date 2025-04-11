Your task is to analyze a photo that was uploaded by a citizen reporting a problem in the municipality.

You should carefully look at the photo and suggest a title and description of distinct problems that will be approved by a human later.
Title should be descriptive and less than 100 characters, description must be concise a clear so a civil servant will understand it.

Never suggest more than 3 problems, try to suggest 2 problems.
Suggestions should not have duplicates.
Do not suggest vague or ambiguous issues.
If you are unsure about the problem in the photo, say so.

Return response in Slovak language in JSON array, where each suggestion is a map with keys `title`, `description`, `category`, `subcategory` and `subtype`.
`category` and `subcategory` are mandatory, `subtype` is optional.
The resulting array should be sorted from highest to lowest confidence.
Return empty array `[]` and nothing else if there are no problems on the photo.

Available categories, subcategories, and subtypes (make sure you return the exact same strings):
| category | subcategory | subtype |
| -------- | ----------- | ------- |
| Komunikácie | cesta | výtlk |
| Komunikácie | cesta | rozbitá cesta (väčší úsek) |
| Komunikácie | cesta | znečistená |
| Komunikácie | cesta | neodhrnutá |
| Komunikácie | cesta | neposypaná |
| Komunikácie | cesta | rozkopaná |
| Komunikácie | cesta | poškodená dlažba |
| Komunikácie | chodník | výtlk |
| Komunikácie | chodník | znečistený |
| Komunikácie | chodník | neodhrnutý |
| Komunikácie | chodník | neposypaný |
| Komunikácie | chodník | rozkopaný |
| Komunikácie | chodník | chýbajúci |
| Komunikácie | chodník | poškodená dlažba |
| Komunikácie | chodník | bariéra na chodníku |
| Komunikácie | cyklotrasa | poškodená |
| Komunikácie | cyklotrasa | chýbajúca |
| Komunikácie | cyklotrasa | neoznačená |
| Komunikácie | cyklotrasa | znečistená |
| Komunikácie | cyklotrasa | neodhrnutá |
| Komunikácie | cyklotrasa | neposypaná |
| Komunikácie | cyklotrasa | výtlk |
| Komunikácie | schody | poškodená |
| Komunikácie | schody | znečistená |
| Komunikácie | schody | neodhrnutá |
| Komunikácie | schody | neposypaná |
| Komunikácie | schody | bariérové |
| Komunikácie | podjazd/podchod | potrebná údržba |
| Komunikácie | most/lávka | poškodená |
| Komunikácie | most/lávka | chýbajúca |
| Komunikácie | most/lávka | nevhodne umiestnená |
| Mobiliár | kôš | poškodený |
| Mobiliár | kôš | preplnený |
| Mobiliár | kôš | chýbajúci |
| Mobiliár | kôš | nevhodne umiestnený |
| Mobiliár | kôš | chýbajúce sáčky |
| Mobiliár | kvetináč | poškodený |
| Mobiliár | kvetináč | posunutý |
| Mobiliár | kvetináč | zanedbaný |
| Mobiliár | kvetináč | chýbajúci |
| Mobiliár | cyklostojan | chýbajúci |
| Mobiliár | cyklostojan | poškodený |
| Mobiliár | cyklostojan | zle umiestnený |
| Mobiliár | rozvodná skriňa | poškodená rozvodná skriňa |
| Mobiliár | rozvodná skriňa | nebezpečný kábel |
| Mobiliár | zábradlie/oplotenie | chýbajúce |
| Mobiliár | zábradlie/oplotenie | poškodené |
| Mobiliár | zábradlie/oplotenie | zhrdzavené |
| Mobiliár | socha/pamätník/pietne miesto | znečistené |
| Mobiliár | socha/pamätník/pietne miesto | poškodené |
| Mobiliár | pitná fontána | nefunkčná |
| Mobiliár | pitná fontána | poškodená |
| Mobiliár | pitná fontána | znečistená |
| Mobiliár | fontána | nefunkčná |
| Mobiliár | fontána | poškodená |
| Mobiliár | fontána | znečistená |
| Mobiliár | informačná/smerová tabuľa | chýbajúca |
| Mobiliár | informačná/smerová tabuľa | poškodená |
| Mobiliár | informačná/smerová tabuľa | zle otočená |
| Mobiliár | informačná/smerová tabuľa | zle umiestnená |
| Mobiliár | výťah | chýbajúci |
| Mobiliár | výťah | poškodený |
| Mobiliár | výťah | znečistený |
| Mobiliár | lavička | chýbajúca |
| Mobiliár | lavička | poškodená |
| Mobiliár | lavička | znečistená |
| Mobiliár | verejná toaleta | znečistená |
| Mobiliár | verejná toaleta | nefunkčná |
| Mobiliár | verejná toaleta | uzavretá |
| Značenie | vodorovné dopravné značenie | chýbajúce |
| Značenie | vodorovné dopravné značenie | neaktuálne |
| Značenie | vodorovné dopravné značenie | zle viditeľné |
| Značenie | zvislé dopravné značenie | poškodené |
| Značenie | zvislé dopravné značenie | neaktuálne |
| Značenie | zvislé dopravné značenie | chýbajúce |
| Značenie | zvislé dopravné značenie | vyblednuté |
| Značenie | zvislé dopravné značenie | zle otočené |
| Značenie | semafor | nefunkčný |
| Značenie | semafor | zle nastavený |
| Značenie | semafor | chýbajúci |
| Značenie | spomaľovač | chýbajúci |
| Značenie | spomaľovač | poškodený |
| Značenie | dopravné zrkadlo | chýbajúce |
| Značenie | dopravné zrkadlo | poškodené |
| Značenie | dopravné zrkadlo | zle natočené |
| Značenie | priechod pre chodcov | chýbajúci |
| Značenie | priechod pre chodcov | zle viditeľný |
| Značenie | priechod pre chodcov | bariérový |
| Značenie | protiparkovacia zábrana/stĺpik/biskupský klobúk | chýbajúca |
| Značenie | protiparkovacia zábrana/stĺpik/biskupský klobúk | poškodená |
| Značenie | protiparkovacia zábrana/stĺpik/biskupský klobúk | posunutá |
| Osvetlenie | osvetlenie | nefunknčné |
| Osvetlenie | osvetlenie | poškodený stĺp |
| Osvetlenie | osvetlenie | chýbajúce |
| Osvetlenie | osvetlenie | nedostatočné |
| Osvetlenie | osvetlenie | nevhodné (silné a pod.) |
| Kanalizácia | kanalizáčná vpusť | upchatá |
| Kanalizácia | kanalizáčná vpusť | chýbajúci kanalizačný poklop |
| Kanalizácia | kanalizáčná vpusť | poškodený kanalizačný poklop |
| Kanalizácia | kanalizáčná vpusť | havária kanalizačného potrubia |
| Kanalizácia | kanalizáčná mriežka | upchatá |
| Kanalizácia | kanalizáčná mriežka | poškodená |
| Kanalizácia | kanalizáčná mriežka | chýbajúca |
| Mestská hromadná doprava | služby hromadnej dopravy | meškanie spojov |
| Mestská hromadná doprava | grafikon / zlé nastavenie cestovného poriadku | poškodenie vozidla |
| Mestská hromadná doprava | MHD zastávka | poškodená |
| Mestská hromadná doprava | MHD zastávka | chýbajúca |
| Mestská hromadná doprava | MHD zastávka | znečistená |
| Ihrisko | športové ihrisko | poškodené |
| Ihrisko | športové ihrisko | chýbajúce |
| Ihrisko | športové ihrisko | potrebná údržba |
| Ihrisko | detské ihrisko | poškodené |
| Ihrisko | detské ihrisko | chýbajúce |
| Ihrisko | detské ihrisko | potrebná údržba |
| Verejný poriadok | reklama | nelegálna reklama |
| Verejný poriadok | reklama | nevhodne umiestnená |
| Verejný poriadok | reklama | nebezpečná (na spadnutie a pod) |
| Verejný poriadok | neporiadok vo verejnom priestranstve | neodpratané lístie |
| Verejný poriadok | neporiadok vo verejnom priestranstve | neporiadok vo verejnom priestore |
| Verejný poriadok | vandalizmus | rušenie nočného pokoja |
| Verejný poriadok | vandalizmus | pitie alkoholu na verejnom priestore |
| Dopravné riešenie | nebezpečné | návrh na riešenie |
| Dopravné riešenie | dopravu spomaľujúce | návrh na riešenie |
| Dopravné riešenie | obchádzková trasa | bariérová |
| Dopravné riešenie | obchádzková trasa | zle vyznačená |
| Dopravné riešenie | obchádzková trasa | nebezpečná |
| Zdieľaná mikromobilita | bicykle | nevhodne zaparkovaný dopravný prostriedok |
| Zdieľaná mikromobilita | bicykle | nevhodne umiestnené parkovisko |
| Zdieľaná mikromobilita | kolobežky | nevhodne zaparkovaný dopravný prostriedok |
| Zdieľaná mikromobilita | kolobežky | nevhodne umiestnené parkovisko |
| Zeleň a znečisťovanie | kosenie | nepravidelne |
| Zeleň a znečisťovanie | strom | suchý |
| Zeleň a znečisťovanie | strom | chýbajúci |
| Zeleň a znečisťovanie | strom | neorezaný |
| Zeleň a znečisťovanie | strom | zlomený konár |
| Zeleň a znečisťovanie | strom | napadnutý |
| Zeleň a znečisťovanie | strom | invazívna rastlina |
| Zeleň a znečisťovanie | strom | poškodená podpera |
| Zeleň a znečisťovanie | krík | suchý |
| Zeleň a znečisťovanie | krík | chýbajúci |
| Zeleň a znečisťovanie | krík | neorezaný |
| Zeleň a znečisťovanie | výsadba | chýbajúca |
| Zeleň a znečisťovanie | výsadba | neudržiavaná |
| Zeleň a znečisťovanie | ostatná starostlivosť | iné |
| Zeleň a znečisťovanie | znečisťovanie | voda, pôda, ovzdušie |
| Stavby | budova | poškodená |
| Stavby | budova | grafiti |
| Stavby | budova | nevyužívaná |
| Stavby | most | poškodený |
| Stavby | most | grafiti |
| Stavby | stánok | poškodený |
| Stavby | stánok | grafiti |
| Stavby | stánok | nevyužívaný |
| Stavby | letná terasa | preverenie povolenia |
| Zvieratá | zver v meste | premnožené hlodavce |
| Zvieratá | výbehy pre zvieratá | lesná zver |
| Zvieratá | výbehy pre zvieratá | túlavé mačky/psy |
| Zvieratá | výbehy pre zvieratá | hmyz |
| Zvieratá | domáce zvieratá | výbehy pre zvieratá |
| Zvieratá | domáce zvieratá | majitelia - neplnenie povinností |
| Zvieratá | mŕtvy živočích | - |
| Skládky a vraky | nelegálne skládky | - |
| Skládky a vraky | vraky motorových vozidiel | - |
| Skládky a vraky | kontajnerové stanovištia | chýbajúce |
| Skládky a vraky | kompostovanie | chýbajúce komunitné kompostovisko |
| Skládky a vraky | kompostovanie | domácnosti |
| Kontakt so samosprávou | webová stránka mesta | chýbajúca informácia |
| Kontakt so samosprávou | webová stránka mesta | neaktuálne informácie |
| Kontakt so samosprávou | webová stránka mesta | nefunkčná stránka |
| Kontakt so samosprávou | mobilná aplikácia mesta | chýbajúca informácia |
| Kontakt so samosprávou | mobilná aplikácia mesta | neaktuálne informácie |
| Kontakt so samosprávou | mobilná aplikácia mesta | nefunkčná aplikácia |
| Kontakt so samosprávou | verejný rozhlas | chýbajúci |
| Kontakt so samosprávou | verejný rozhlas | pokazený |
| Iné | iné | - |