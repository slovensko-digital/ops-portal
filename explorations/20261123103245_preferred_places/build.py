#!/usr/bin/env python3
"""Generates the option pages from one shell. Run: python3 build.py
index.html (problems, options, decision, rounds) is edited by hand."""
from pathlib import Path

ROOT = Path(__file__).parent

VARIANTS = [
    ("0-current", "0 · Dnes", "Pôvodné správanie: výber je len v placeholdri, po dvoch položkách „a ďalšie“.",
     ["Repro problému: 6 vybraných lokalít, vidno 2.", "Odznačiť sa dá len nájdením položky v zozname.", "Správanie 1:1 ako v produkcii (bez Esc, text pri zatvorení ostáva)."]),
    ("a-chips-above", "A · Štítky nad poľom", "Vybrané lokality ako štítky s × nad vyhľadávaním. Pole slúži len na hľadanie.",
     ["Počet v labeli.", "× odstráni lokalitu bez otvárania zoznamu.", "Mestská časť: obec je potlačená, časť zvýraznená.", "Napíšte napr. „xyz“: stav, keď sa nič nenašlo."]),
    ("a2-filter-pills", "A2 · Pilulky ako vo filtri", "Ako A, ale štítky vyzerajú ako aktívne filtre na stránke podnetov.",
     ["Rovnaký komponent ako filter-select-button, svetlomodré pozadie ako panel filtra.", "× vľavo, klik kamkoľvek na pilulku ju odstráni.", "Jeden štýl písma pre obce aj časti, oddeľovač „ - “.", "Napíšte napr. „xyz“: stav, keď sa nič nenašlo."]),
    ("a3-filter-pills-muted", "A3 · Pilulky, obec sivou", "Ako A2, ale pri mestskej časti je obec sivou namiesto oddeľovača „ - “.",
     ["„Bratislava Petržalka“: obec sivá, časť plnou farbou, rovnaká hrúbka písma.", "Samostatná obec bez zmeny.", "Napíšte napr. „xyz“: stav, keď sa nič nenašlo."]),
    ("a4-filter-pills-district", "A4 · Pilulky, len časť", "Ako A2, ale pri mestskej časti sa obec v pilulke nezobrazuje.",
     ["„Petržalka“ namiesto „Bratislava - Petržalka“.", "Celý názov je v tooltipe a pre čítačky obrazovky.", "Pozor: názvy častí sa opakujú (Staré Mesto v Bratislave aj Košiciach) — skúste zaškrtnúť obe.", "Napíšte napr. „xyz“: stav, keď sa nič nenašlo."]),
    ("b-tags-inside", "B · Štítky v poli", "Štítky a vyhľadávanie sú v jednom rámčeku, ako tag input.",
     ["Klik kamkoľvek do rámčeka zameria vyhľadávanie.", "Backspace v prázdnom poli odstráni posledný štítok.", "Pri veľa lokalitách rámček rastie do výšky.", "Nevybraná alternatíva — pre porovnanie s A."]),
    ("c-selected-list", "C · Zoznam pod poľom", "Pole slúži len na hľadanie, vybrané lokality sú ako zoznam riadkov pod ním.",
     ["Mestské časti sú zoskupené pod svojou obcou.", "Počet „Sledujete N lokalít“ a „Zrušiť všetky“.", "Každý riadok má vlastné ×.", "Nevybraná alternatíva — pre porovnanie s A."]),
    ("d-summary-rows", "D · Súhrn a úprava", "Zatvorené pole ukáže celý výber ako text na viac riadkov, „Upraviť“ otvorí hľadanie.",
     ["Po otvorení sú vybrané lokality pripnuté hore v zozname („Vybrané“).", "Odznačenie priamo v pripnutej časti, „Zrušiť všetky“.", "Esc zavrie a vráti súhrn.", "Nevybraná alternatíva — pre porovnanie s A."]),
]

FIELDS = {
"0-current": """
<div class="form-item-wrapper" data-controller="current"
     data-action="keydown.enter->current#enter click@window->current#close">
  <label for="preferred_places">Preferované mestá alebo obce</label>
  <div class="autocomplete-wrapper">
    <input type="text" class="form-input" id="preferred_places" autocomplete="off"
           data-current-target="input" data-action="focusin->current#open input->current#filter">
    <ul class="dropdown-list none" data-current-target="list" data-places-list="current"></ul>
  </div>
</div>""",

"a-chips-above": """
<div class="form-item-wrapper" data-controller="chips"
     data-action="keydown.enter->chips#enter keydown.esc->chips#escape click@window->chips#close">
  <label for="preferred_places">Preferované mestá alebo obce <span class="place-count" data-chips-target="count"></span></label>
  <div class="autocomplete-wrapper">
    <div class="place-chips" data-chips-target="chips" aria-live="polite"></div>
    <input type="text" class="form-input" id="preferred_places" autocomplete="off"
           data-chips-target="input" data-action="focusin->chips#open input->chips#filter">
    <ul class="dropdown-list none" data-chips-target="list" data-places-list="chips"></ul>
    <div class="place-empty none" data-chips-target="empty" role="status"></div>
  </div>
</div>""",

"a2-filter-pills": """
<div class="form-item-wrapper" data-controller="pills"
     data-action="keydown.enter->pills#enter keydown.esc->pills#escape click@window->pills#close">
  <label for="preferred_places">Preferované mestá alebo obce <span class="place-count" data-pills-target="count"></span></label>
  <div class="autocomplete-wrapper">
    <div class="filter-select-buttons-con place-pills" data-pills-target="chips" aria-live="polite"></div>
    <input type="text" class="form-input" id="preferred_places" autocomplete="off"
           data-pills-target="input" data-action="focusin->pills#open input->pills#filter">
    <ul class="dropdown-list none" data-pills-target="list" data-places-list="pills"></ul>
    <div class="place-empty none" data-pills-target="empty" role="status"></div>
  </div>
</div>""",

"a4-filter-pills-district": """
<div class="form-item-wrapper" data-controller="pills-district"
     data-action="keydown.enter->pills-district#enter keydown.esc->pills-district#escape click@window->pills-district#close">
  <label for="preferred_places">Preferované mestá alebo obce <span class="place-count" data-pills-district-target="count"></span></label>
  <div class="autocomplete-wrapper">
    <div class="filter-select-buttons-con place-pills" data-pills-district-target="chips" aria-live="polite"></div>
    <input type="text" class="form-input" id="preferred_places" autocomplete="off"
           data-pills-district-target="input" data-action="focusin->pills-district#open input->pills-district#filter">
    <ul class="dropdown-list none" data-pills-district-target="list" data-places-list="pills-district"></ul>
    <div class="place-empty none" data-pills-district-target="empty" role="status"></div>
  </div>
</div>""",

"a3-filter-pills-muted": """
<div class="form-item-wrapper" data-controller="pills-muted"
     data-action="keydown.enter->pills-muted#enter keydown.esc->pills-muted#escape click@window->pills-muted#close">
  <label for="preferred_places">Preferované mestá alebo obce <span class="place-count" data-pills-muted-target="count"></span></label>
  <div class="autocomplete-wrapper">
    <div class="filter-select-buttons-con place-pills" data-pills-muted-target="chips" aria-live="polite"></div>
    <input type="text" class="form-input" id="preferred_places" autocomplete="off"
           data-pills-muted-target="input" data-action="focusin->pills-muted#open input->pills-muted#filter">
    <ul class="dropdown-list none" data-pills-muted-target="list" data-places-list="pills-muted"></ul>
    <div class="place-empty none" data-pills-muted-target="empty" role="status"></div>
  </div>
</div>""",

"b-tags-inside": """
<div class="form-item-wrapper" data-controller="chips"
     data-action="keydown.enter->chips#enter keydown.esc->chips#escape click@window->chips#close">
  <label for="preferred_places">Preferované mestá alebo obce <span class="place-count" data-chips-target="count"></span></label>
  <div class="autocomplete-wrapper">
    <div class="place-tagbox" data-keep-open data-action="click->chips#focusInput">
      <div class="place-chips" data-chips-target="chips" aria-live="polite"></div>
      <input type="text" class="place-tagbox-input" id="preferred_places" autocomplete="off"
             data-chips-target="input"
             data-action="focusin->chips#open input->chips#filter keydown->chips#backspace">
    </div>
    <ul class="dropdown-list none" data-chips-target="list" data-places-list="chips"></ul>
  </div>
</div>""",

"c-selected-list": """
<div class="form-item-wrapper" data-controller="list"
     data-action="keydown.enter->list#enter keydown.esc->list#escape click@window->list#close">
  <label for="preferred_places">Preferované mestá alebo obce</label>
  <div class="autocomplete-wrapper">
    <input type="text" class="form-input" id="preferred_places" autocomplete="off" placeholder="Vyhľadajte a pridajte lokalitu..."
           data-list-target="input" data-action="focusin->list#open input->list#filter">
    <ul class="dropdown-list none" data-list-target="list" data-places-list="list"></ul>
  </div>
  <div class="place-selected-head">
    <span data-list-target="summary" aria-live="polite"></span>
    <button type="button" class="place-link" data-action="list#clearAll">Zrušiť všetky</button>
  </div>
  <ul class="place-rows" data-list-target="selected"></ul>
</div>""",

"d-summary-rows": """
<div class="form-item-wrapper" data-controller="summary"
     data-action="keydown.enter->summary#enter keydown.esc->summary#escape click@window->summary#close">
  <label for="preferred_places">Preferované mestá alebo obce</label>
  <div class="autocomplete-wrapper">
    <button type="button" class="place-summary" data-keep-open data-summary-target="summary" data-action="summary#edit">
      <span class="place-summary-text"></span>
      <span class="place-summary-edit">Upraviť</span>
    </button>
    <div class="none" data-summary-target="editor">
      <input type="text" class="form-input" id="preferred_places" autocomplete="off" placeholder="Vyhľadajte lokality..."
             data-summary-target="input" data-action="focusin->summary#open input->summary#filter">
    </div>
    <div class="place-dropdown none" data-summary-target="list">
      <ul class="dropdown-list" data-summary-target="pinned"></ul>
      <ul class="dropdown-list" data-places-list="summary"></ul>
    </div>
  </div>
</div>""",
}

def nav(current):
    links = "".join(
        f'<a href="{slug}.html"{" aria-current=page" if slug == current else ""}>{title}</a>'
        for slug, title, *_ in VARIANTS
    )
    toggle = ('<label class="proto-toggle"><input type="checkbox" data-controller="proto-toggle" '
              'data-action="proto-toggle#change"> Rovnaký vzhľad obcí a častí</label>')
    return f'<nav class="proto-bar"><a href="/explorations">Explorations</a><a href="index.html"><strong>Prototyp · Preferované lokality</strong></a>{links}{toggle if current == "a-chips-above" else ""}</nav>'


def head(title):
    return f"""<!DOCTYPE html>
<html lang="sk">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>{title} | Prototyp</title>
  <link rel="stylesheet" href="assets/app.css">
  <link rel="stylesheet" href="assets/proto.css">
  <script type="module" src="js/app.js"></script>
</head>"""


def page(slug, title, desc, notes):
    field = FIELDS[slug]
    notes_html = "".join(f"<li>{n}</li>" for n in notes)
    return f"""{head(title)}
<body>
{nav(slug)}
<div class="proto-page">
  <div class="proto-note"><strong>{title}</strong> — {desc}<ul>{notes_html}</ul></div>

  <section class="forms-container report">
    <h1>Osobné údaje</h1>
    <form data-controller="payload" data-action="submit->payload#show">
      <div class="form-other-con">
        <div class="form-items-con">
          <div class="form-item-wrapper">
            <label for="user_name">Meno*</label>
            <input type="text" id="user_name" name="user[name]" value="Jana Nováková">
          </div>
        </div>

        <div class="form-items-con">
          <input type="hidden" name="user[municipality_ids][]" value="">
          <input type="hidden" name="user[municipality_district_ids][]" value="">
{field}
          <div class="form-notice">
            Vyhľadajte a zaškrtnite si mestá a mestské časti, z ktorých chcete vidieť najviac podnetov a dostávať novinky.
          </div>
        </div>

        <div class="form-items-con">
          <div class="form-description">Chcete dostávať emailové notifikácie k&nbsp;podnetom?</div>
          <div class="form-radio-button-wrapper">
            <div class="form-radio-button-con">
              <input type="radio" id="en_true" name="user[email_notifiable]" value="true" checked>
              <label for="en_true">Áno</label>
            </div>
            <div class="form-radio-button-con">
              <input type="radio" id="en_false" name="user[email_notifiable]" value="false">
              <label for="en_false">Nie</label>
            </div>
          </div>
        </div>
      </div>
      <input type="submit" class="button" value="Uložiť">
      <pre class="proto-payload none" data-payload-target="output"></pre>
    </form>
  </section>
</div>
</body>
</html>
"""


for slug, title, desc, notes in VARIANTS:
    (ROOT / f"{slug}.html").write_text(page(slug, title, desc, notes))
print("built", len(VARIANTS), "pages; index.html is written by hand")
