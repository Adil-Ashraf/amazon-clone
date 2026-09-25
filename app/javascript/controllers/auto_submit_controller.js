import { Controller } from "@hotwired/stimulus"

// Submits its form as soon as a control changes (e.g. the sort <select>).
// The form still has a submit button for when JavaScript is off. With a
// media value it only auto-submits while that media query matches, so the
// mobile filter drawer can wait for "Show results" instead.
export default class extends Controller {
  static values = { media: String }

  submit() {
    if (this.hasMediaValue && !window.matchMedia(this.mediaValue).matches) return

    this.element.requestSubmit()
  }
}
