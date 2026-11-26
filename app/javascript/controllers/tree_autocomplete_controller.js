import SearchableSelectController from "controllers/searchable_select_controller"

// A searchable tree: municipalities (data-level="0") followed by their districts (data-level="1").
// Filtering keeps the tree order: a matching district keeps its municipality visible, and a matching
// municipality shows all of its districts (district names repeat across cities, so the parent tells
// them apart).
export default class TreeAutocompleteController extends SearchableSelectController {
    showMatches(query) {
        let municipalityItem = null
        let municipalityMatch = false

        this.itemTargets.forEach(item => {
            const match = this.normalizeString(item.dataset.fullLabel).includes(query)

            if (item.dataset.level === "0") {
                municipalityItem = item
                municipalityMatch = match
                item.classList.toggle("none", !match)
            } else {
                item.classList.toggle("none", !(match || municipalityMatch))
                if (match) municipalityItem?.classList.remove("none")
            }
        })
    }
}
