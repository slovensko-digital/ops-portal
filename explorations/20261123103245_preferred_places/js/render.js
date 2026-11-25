// Stands in for the server: renders the same markup as
// app/views/profiles/_preferred_place_item.html.erb into every [data-places-list].
import { municipalities } from "./data.js"

const CHECK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 20"><polygon points="5.51 15.78 0 10.26 1.06 9.2 5.51 13.66 14.94 4.22 16 5.28 5.51 15.78"/></svg>`

function escape(s) {
  return s.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
}

function item(it, identifier) {
  const field = it.is_district ? "municipality_district_ids" : "municipality_ids"
  const classes = ["check-box", it.is_district && "district", it.selected && "active"].filter(Boolean).join(" ")
  return `
    <li class="${classes}" data-${identifier}-target="item">
      <label class="check-box-label${it.is_district ? " check-box-label--district" : ""}">
        <input type="checkbox" class="sr-only" name="user[${field}][]" value="${it.id}"
          ${it.selected ? "checked" : ""}
          data-${identifier}-target="checkbox"
          data-label="${escape(it.label)}"
          data-full-label="${escape(it.full_label)}"
          data-municipality="${escape(it.full_label.split(" - ")[0])}"
          data-district="${it.is_district}"
          data-action="change->${identifier}#toggle">
        <div class="form-check-box">${CHECK_SVG}</div>
        <span class="${it.is_district ? "" : "item-title--bold"}">${escape(it.label)}</span>
      </label>
    </li>`
}

document.querySelectorAll("[data-places-list]").forEach(ul => {
  const identifier = ul.dataset.placesList
  ul.innerHTML = municipalities
    .flatMap(m => [item(m, identifier), ...m.districts.map(d => item(d, identifier))])
    .join("")
})
