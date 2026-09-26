import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Typeahead for the header search boxes, on every page (on the catalog it
// runs alongside live_search_controller.js). After a pause in typing it
// points a Turbo Frame at /search_suggestions?query=..., which the server
// fills from the same pg_search scope as the catalog. Setting a new src
// makes Turbo abort the previous request, so an older response can never
// replace a newer one.
//
// Keyboard: the input keeps focus (WAI-ARIA combobox); arrows move the
// highlighted option via aria-activedescendant, Enter opens it, Esc closes.
// With nothing highlighted, Enter submits the form as a normal search.
export default class extends Controller {
  static targets = ["input", "panel", "frame", "message", "option"]
  static values = { url: String, minLength: { type: Number, default: 2 }, delay: { type: Number, default: 300 } }

  // A page restored from Turbo's cache may have been cached with the
  // dropdown open; it always starts closed. (Closing on turbo:before-cache
  // instead would also fire on every live catalog update and shut it.)
  connect() {
    this.activeIndex = -1
    this.close()
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.query

    if (query.length < this.minLengthValue) {
      this.lastQuery = null
      this.close()
      return
    }

    this.timeout = setTimeout(() => this.load(query), this.delayValue)
  }

  load(query) {
    if (query === this.lastQuery) {
      this.open()
      return
    }

    this.lastQuery = query
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("query", query)

    if (!this.frameTarget.hasChildNodes()) this.showMessage("Searching…")
    this.open()
    this.frameTarget.src = url.toString()
  }

  loaded() {
    this.hideMessage()
    this.activeIndex = -1
    this.inputTarget.removeAttribute("aria-activedescendant")
    if (this.query.length < this.minLengthValue) this.close()
  }

  // Network failure: keep the box usable and say so.
  failed(event) {
    event.preventDefault()
    this.lastQuery = null
    this.frameTarget.replaceChildren()
    this.showMessage("Suggestions aren't available right now. Press Enter to search.")
  }

  // An error status (404, 500...): stop Turbo from processing the response
  // at all -- Rails error pages ask for a full reload, which would take the
  // shopper away from the page they're on -- and show the message instead.
  checkResponse(event) {
    if (!event.detail.fetchResponse.succeeded) this.failed(event)
  }

  // A successful response without the frame in it: don't let Turbo
  // navigate to it; show the same message.
  missing(event) {
    this.failed(event)
  }

  navigate(event) {
    if (this.panelTarget.hidden) {
      if (event.key === "ArrowDown" && this.query.length >= this.minLengthValue) {
        event.preventDefault()
        this.load(this.query)
      }
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlight(this.activeIndex + 1)
        break
      case "ArrowUp":
        event.preventDefault()
        // From nothing highlighted, Up goes to the last option.
        this.highlight(this.activeIndex < 0 ? this.optionTargets.length - 1 : this.activeIndex - 1)
        break
      case "Enter":
        if (this.activeOption) {
          event.preventDefault()
          if ("searchSuggestViewAll" in this.activeOption.dataset) {
            this.submitSearch()
          } else {
            Turbo.visit(this.activeOption.href)
            this.close()
          }
        }
        break
      case "Escape":
        // Close the suggestions only; a second Esc reaches the page (e.g.
        // closes the mobile search panel).
        event.preventDefault()
        event.stopPropagation()
        this.close()
        break
    }
  }

  // The pointer highlights too, but never scrolls the list under it.
  // "View all" runs the box's own search (the form), so on the catalog it
  // keeps the current category and filters; the link's href is the no-JS
  // fallback.
  viewAll(event) {
    event.preventDefault()
    this.submitSearch()
  }

  submitSearch() {
    this.close()
    this.element.requestSubmit()
  }

  hover(event) {
    this.highlight(this.optionTargets.indexOf(event.currentTarget), { scroll: false })
  }

  reopen() {
    if (this.query.length >= this.minLengthValue && this.query === this.lastQuery) this.open()
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  // Submitting runs the normal search; the suggestions are done.
  submitted() {
    clearTimeout(this.timeout)
    this.close()
  }

  highlight(index, { scroll = true } = {}) {
    const options = this.optionTargets
    if (options.length === 0) return

    this.activeIndex = (index + options.length) % options.length
    options.forEach((option, i) => option.setAttribute("aria-selected", i === this.activeIndex ? "true" : "false"))
    this.inputTarget.setAttribute("aria-activedescendant", this.activeOption.id)
    if (scroll) this.activeOption.scrollIntoView({ block: "nearest" })
  }

  open() {
    this.panelTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
    this.activeIndex = -1
    this.optionTargets.forEach((option) => option.setAttribute("aria-selected", "false"))
  }

  showMessage(text) {
    this.messageTarget.textContent = text
    this.messageTarget.hidden = false
  }

  hideMessage() {
    this.messageTarget.hidden = true
  }

  get query() {
    return this.inputTarget.value.trim()
  }

  get activeOption() {
    return this.activeIndex >= 0 ? this.optionTargets[this.activeIndex] : null
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.close()
  }
}
