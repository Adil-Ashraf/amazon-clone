import { Controller } from "@hotwired/stimulus"

// Disclosure menu: the button toggles the panel; a click outside or Esc
// closes it. An optional focus target (e.g. a search field) gets focus
// when the panel opens. Window listeners are Stimulus actions on the element
// (click@window, keydown.esc@window), so Stimulus removes them on disconnect.
export default class extends Controller {
  static targets = ["button", "panel", "focus"]

  toggle() {
    this.panelTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.panelTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    if (this.hasFocusTarget) this.focusTarget.focus()
  }

  close() {
    if (this.panelTarget.hidden) return

    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape() {
    if (this.panelTarget.hidden) return

    this.close()
    this.buttonTarget.focus()
  }

  // Leave the menu closed if Turbo caches the page or the element is removed.
  disconnect() {
    this.close()
  }
}
