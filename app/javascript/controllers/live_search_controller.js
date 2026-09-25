import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Live search on the catalog: debounces typing in a header search box and
// reloads the product results Turbo Frame (pg_search on the server) with
// Turbo.visit(url, { frame }), which also updates the address bar, so a
// search is shareable and back / forward work. The first update of a typing
// burst adds a history entry; later keystrokes replace it, so Back returns
// to the listing from before the search rather than to "h", "he", "hea".
//
// Visiting the frame (rather than calling requestSubmit() on every pause)
// keeps the browser from saving each partial query in its autofill history.
// Turbo cancels the frame's in-flight request when a new visit starts, so a
// slow response for an older query can't overwrite a newer one.
//
// The URL is built from the current catalog URL, so category, sort, filters
// and view survive; only the query changes and paging restarts at 1.
// Without JavaScript, or on pages without the frame, the form is a normal
// GET search.
export default class extends Controller {
  static targets = ["input", "status"]
  static values = { delay: { type: Number, default: 300 }, frame: String }

  // Back / Forward restore a cached copy of the page, including whatever was
  // in the box when it was cached, so match the box to the URL on connect.
  connect() {
    this.syncInput()
  }

  search() {
    clearTimeout(this.timeout)
    this.pending = true
    this.timeout = setTimeout(() => this.updateFrame(), this.delayValue)
  }

  // Enter on the catalog runs the same search immediately, keeping filters.
  submit(event) {
    if (!this.frame) return

    event.preventDefault()
    clearTimeout(this.timeout)
    this.updateFrame({ action: "advance" })
    this.typing = false
  }

  // The next keystroke after leaving the box starts a new history entry.
  blur() {
    this.typing = false
  }

  updateFrame({ action } = {}) {
    this.pending = false
    const frame = this.frame
    if (!frame) return

    const url = new URL(window.location.href)
    const query = this.inputTarget.value.trim()
    url.searchParams.delete("page")
    if (query) {
      url.searchParams.set("query", query)
    } else {
      url.searchParams.delete("query")
      if (url.searchParams.get("sort") === "relevance") url.searchParams.delete("sort")
    }

    if (url.href === (frame.src || window.location.href)) return

    this.searching = true
    Turbo.visit(url.href, { frame: this.frameValue, action: action || (this.typing ? "replace" : "advance") })
    this.typing = true
  }

  // After the results frame loads: announce the match count for this box's
  // own search; for any other navigation (Back / Forward, pagination,
  // filters) bring the box in line with the URL, unless a keystroke is still
  // waiting to be searched.
  frameLoaded(event) {
    if (event.target !== this.frame) return

    if (this.searching) {
      this.searching = false
      const summary = document.getElementById("results_summary")
      if (this.hasStatusTarget) this.statusTarget.textContent = summary ? summary.textContent.trim() : ""
    } else if (!this.pending) {
      this.syncInput()
    }
  }

  syncInput() {
    this.inputTarget.value = new URL(window.location.href).searchParams.get("query") || ""
  }

  get frame() {
    return this.frameValue ? document.getElementById(this.frameValue) : null
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
