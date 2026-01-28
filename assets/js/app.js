// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/checkers"
import topbar from "../vendor/topbar"

// Drag and Drop Hooks
const DragDropHooks = {
  Draggable: {
    mounted() {
      this.el.setAttribute("draggable", "true")
      
      this.el.addEventListener("dragstart", (e) => {
        e.dataTransfer.setData("text/plain", this.el.dataset.id)
        e.dataTransfer.effectAllowed = "move"
        this.el.classList.add("opacity-50", "scale-95")
        // Notify other drop zones that drag has started
        document.dispatchEvent(new CustomEvent("drag-started", { detail: { id: this.el.dataset.id } }))
      })
      
      this.el.addEventListener("dragend", (e) => {
        this.el.classList.remove("opacity-50", "scale-95")
        document.dispatchEvent(new CustomEvent("drag-ended"))
      })
    }
  },
  
  DropZone: {
    mounted() {
      this.el.addEventListener("dragover", (e) => {
        e.preventDefault()
        e.dataTransfer.dropEffect = "move"
        this.el.classList.add("ring-2", "ring-blue-400", "bg-blue-50", "dark:bg-blue-900/20")
      })
      
      this.el.addEventListener("dragleave", (e) => {
        this.el.classList.remove("ring-2", "ring-blue-400", "bg-blue-50", "dark:bg-blue-900/20")
      })
      
      this.el.addEventListener("drop", (e) => {
        e.preventDefault()
        this.el.classList.remove("ring-2", "ring-blue-400", "bg-blue-50", "dark:bg-blue-900/20")
        const id = e.dataTransfer.getData("text/plain")
        const action = this.el.dataset.dropAction
        if (action && id) {
          this.pushEvent(action, { id: id })
        }
      })
      
      // Show visual indicator when drag starts
      document.addEventListener("drag-started", (e) => {
        this.el.classList.add("transition-all")
      })
      
      document.addEventListener("drag-ended", () => {
        this.el.classList.remove("ring-2", "ring-blue-400", "bg-blue-50", "dark:bg-blue-900/20")
      })
    }
  },
  
  SortableGrid: {
    mounted() {
      this.setupDragDrop()
    },
    
    updated() {
      // Re-setup after LiveView updates
      this.setupDragDrop()
    },
    
    setupDragDrop() {
      const cards = this.el.querySelectorAll("[data-sortable-id]")
      
      cards.forEach(card => {
        card.setAttribute("draggable", "true")
        
        card.addEventListener("dragstart", (e) => {
          e.dataTransfer.setData("text/plain", card.dataset.sortableId)
          e.dataTransfer.effectAllowed = "move"
          card.classList.add("opacity-50", "scale-95")
          document.dispatchEvent(new CustomEvent("drag-started", { detail: { id: card.dataset.sortableId } }))
        })
        
        card.addEventListener("dragend", () => {
          card.classList.remove("opacity-50", "scale-95")
          document.dispatchEvent(new CustomEvent("drag-ended"))
        })
        
        card.addEventListener("dragover", (e) => {
          e.preventDefault()
          const dragging = this.el.querySelector(".opacity-50")
          if (dragging && dragging !== card) {
            const rect = card.getBoundingClientRect()
            const midY = rect.top + rect.height / 2
            if (e.clientY < midY) {
              card.parentNode.insertBefore(dragging, card)
            } else {
              card.parentNode.insertBefore(dragging, card.nextSibling)
            }
          }
        })
        
        card.addEventListener("drop", (e) => {
          e.preventDefault()
          // Collect new order and send to server
          const newOrder = Array.from(this.el.querySelectorAll("[data-sortable-id]"))
            .map(c => c.dataset.sortableId)
          this.pushEvent("reorder_notes", { ids: newOrder })
        })
      })
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...DragDropHooks},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

