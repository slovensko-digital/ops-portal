# Glossary

| Term | Meaning |
|---|---|
| RS | Responsible subject (zodpovedný subjekt): municipality, district, or other organization |
| Stav (OPS) | Triage ticket attribute `ops_state`, labelled "Stav v Odkaze pre starostu". Holds the portal state key (`waiting`, `sent_to_responsible`…). The volunteer accepts, rejects or asks for a supplement here |
| Stav (Triage Zammad) | Zammad's built-in "Stav" (`state_id`: new, open, closed…). Internal to Triage and not synced to the portal. Automation sets it, don't change it by hand |
| Doplnenie | Supplement: volunteer asks the author for more info (`waiting_for_author`) |
| Pochvala | Praise |
| Podúlohy | Subtasks inside Backoffice, created from a note with `[[podulohy]]` and `@@user … - date` lines. Not available in Triage ([07](07-backoffice-connector.md#subtasks-podúlohy)) |
| `[[ops portal]]`, `[[pre zodpovedny subjekt]]` | Tags in Triage article bodies that decide where a comment goes ([06](06-comments-likes-routing.md)) |
| 700 rule | Triage trigger `700 - Priradenie podnetu skupine <Obec> <Agent>` that routes a new ticket to a municipality group, owner and RS |
