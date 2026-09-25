import { Controller } from "@hotwired/stimulus"

// Submits its form as soon as a control changes (e.g. the sort <select>).
// The form still has a submit button for when JavaScript is off.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
