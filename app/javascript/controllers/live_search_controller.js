import { Controller } from "@hotwired/stimulus"

// Debounces typing in the nav search box into an auto-submit, so the product
// grid updates live without waiting for Enter or a full page reload.
export default class extends Controller {
  static targets = ["form"]
  static values = { delay: { type: Number, default: 300 } }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.formTarget.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
