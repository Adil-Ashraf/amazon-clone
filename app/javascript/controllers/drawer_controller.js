import { Controller } from "@hotwired/stimulus"

// A slide-over drawer built on <dialog>: showModal() gives focus trapping,
// Esc to close and inert page content for free. A click on the backdrop
// (the dialog element itself, outside its panel) also closes it.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // Don't leave a modal open in a Turbo cache snapshot.
  disconnect() {
    this.close()
  }
}
