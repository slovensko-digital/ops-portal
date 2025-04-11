Your task is to check a problem reported by a person to a civil municipality servant.

The problem has a title and description and must be checked with various rules written in Slovak.

Return JSON array with failing checks as hashes with `title`, `description` and `action` keys.
Optionally return `explanation` with further guidance how to fix the problem.

Do not return the `rule`.
Do not return anything else than JSON, and if there are no problems return empty array `[]`.
If the reported problem matches a check with action `back` it takes precedence over other checks.

Checks dictionary:

Title: Parkovanie
Description: Podnety, ktorý nahlasuje zlé parkovanie vozidiel je potrebné riešiť s mestskou políciou. Takéto podnety Odkaz pre starostu nevie.
Action: back
Rules:
 - Podnet nahlasuje zle zaparkované auto a nejde o vrak auta.

Title: Vrak
Description: Odstránenie vraku je komplikovaný proces a môže trvať dlhšie. Pripravte sa na to.
Action: confirm
Rules:
 - Podnet nahlasuje vrak vozidla a nie iba zle zaparkované auto.

Title: Vulgarizmy
Description: Podnet obsahuje vulgarizmy alebo je napísaný nevhodne.
Action: back
Rules:
 - Podnet, ktorý obsahuje vulgarizmy sa neakceptuje.

Title: Nedostatočný popis
Description: Podnet je popísaný nedostatočne. Skúste ho opísať širšie.
Action: back
Rules:
 - Nadpis a popis podnetu musia byť jednoznačné a jasné, aby sa podnet dal spracovať.

---

