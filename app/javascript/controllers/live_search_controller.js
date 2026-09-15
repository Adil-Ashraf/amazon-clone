import { Controller } from "@hotwired/stimulus"

// Debounces typing in the nav search box and updates the product results
// Turbo Frame directly (by setting its `src`), instead of calling the native
// form's requestSubmit() on every keystroke. requestSubmit() performs a real
// form submission, which the browser's own per-field autofill history
// tracks -- doing that on every debounced keystroke recorded each partial
// value typed along the way ("l", "laptop s", "laptop stand"...) as a
// separate remembered suggestion, which is what showed up stacking in the
// browser's native autocomplete dropdown. Setting the frame's src bypasses
// native form-submission semantics entirely, so nothing gets remembered
// until the user actually presses Enter or clicks Search.
export default class extends Controller {
  static targets = ["input"]
  static values = { delay: { type: Number, default: 300 }, frame: String, url: String }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.updateFrame(), this.delayValue)
  }

  updateFrame() {
    const frame = document.getElementById(this.frameValue)
    if (!frame) return

    const url = new URL(this.urlValue, window.location.origin)
    const query = this.inputTarget.value.trim()
    if (query) {
      url.searchParams.set("query", query)
    } else {
      url.searchParams.delete("query")
    }

    frame.src = url.toString()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
