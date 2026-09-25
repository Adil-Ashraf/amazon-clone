import { Controller } from "@hotwired/stimulus"

// Generic dismiss-on-click for toasts/banners: removes the element itself.
// An optional timeout (ms) removes it automatically; 0 means never.
export default class extends Controller {
  static values = { timeout: { type: Number, default: 0 } }

  connect() {
    if (this.timeoutValue > 0) {
      this.timeout = setTimeout(() => this.close(), this.timeoutValue)
    }
  }

  close() {
    this.element.remove()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
