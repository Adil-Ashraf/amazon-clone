import { Controller } from "@hotwired/stimulus"

// A product photo layered over its designed tile. If the photo can't load,
// remove it so the tile shows through, and expose the tile to assistive tech
// (it is aria-hidden while the photo covers it). connect() also catches a
// photo that failed before this controller was attached.
export default class extends Controller {
  static targets = ["tile", "photo"]

  connect() {
    if (this.hasPhotoTarget && this.photoTarget.complete && this.photoTarget.naturalWidth === 0) {
      this.fallback()
    }
  }

  fallback() {
    if (this.hasPhotoTarget) this.photoTarget.remove()
    this.tileTarget.removeAttribute("aria-hidden")
  }
}
