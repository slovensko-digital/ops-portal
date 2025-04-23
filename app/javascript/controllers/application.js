import { Application } from "@hotwired/stimulus"
import { Alert, Autosave, ColorPreview, Dropdown, Modal, Tabs, Popover, Toggle, Slideover } from "tailwindcss-stimulus-components"
import AutoSubmit from "@stimulus-components/auto-submit"


const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Import and register all TailwindCSS Components or just the ones you need
application.register('alert', Alert)
application.register('autosave', Autosave)
application.register('color-preview', ColorPreview)
application.register('dropdown', Dropdown)
application.register('dropdown-navbar', Dropdown)
application.register('modal', Modal)
application.register('popover', Popover)
application.register('slideover', Slideover)
application.register('tabs', Tabs)
application.register('toggle', Toggle)

application.register('auto-submit', AutoSubmit)

document.addEventListener('turbo:before-cache', function({ target}) {
    const setOpenAsFalse = (attribute) => {
        const element = target.querySelector(`[${attribute}="true"]`)
        element?.setAttribute(attribute, "false")
    }

    const queryAllAndModify = (selector, modify) => {
        target.querySelectorAll(selector).forEach(modify)
    }

    const addHiddenClass = () => {
        queryAllAndModify("[data-turbo-temporary-hide]", (elm) => {
            if (!elm.classList.contains('hidden')) {
                elm.classList.add('hidden')
            }
        })
    }

    addHiddenClass()
    setOpenAsFalse('data-slideover-open-value')
    setOpenAsFalse('data-dropdown-open-value')
    setOpenAsFalse('data-toggle-open-value')
})

export { application }
