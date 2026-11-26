document.documentElement.classList.toggle("uniform-places", localStorage.getItem("uniform-places") === "1")

import "./render.js"
import { Application } from "./stimulus.js"
import { CurrentController, ChipsController, PillsController, PillsMutedController, PillsDistrictController, ListController, SummaryController, PayloadController, ProtoToggleController } from "./variants.js"

const app = Application.start()
app.register("current", CurrentController)
app.register("chips", ChipsController)
app.register("pills", PillsController)
app.register("pills-muted", PillsMutedController)
app.register("pills-district", PillsDistrictController)
app.register("list", ListController)
app.register("summary", SummaryController)
app.register("payload", PayloadController)
app.register("proto-toggle", ProtoToggleController)
