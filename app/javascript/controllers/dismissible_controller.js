import { Controller } from "@hotwired/stimulus"

// Generic dismiss-on-click for toasts/banners: removes the element itself.
export default class extends Controller {
  close() {
    this.element.remove()
  }
}
