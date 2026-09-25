import { Controller } from "@hotwired/stimulus"

// A product photo over a neutral well. The designed tile underneath is
// hidden while the photo loads; only if the photo can't load is it removed
// and the tile revealed (and exposed to assistive tech). connect() also
// catches a photo that failed before this controller was attached.
export default class extends Controller {
  static targets = ["tile", "photo"]

  connect() {
    if (this.hasPhotoTarget && this.photoTarget.complete && this.photoTarget.naturalWidth === 0) {
      this.fallback()
    }
  }

  fallback() {
    if (this.hasPhotoTarget) this.photoTarget.remove()
    this.tileTarget.hidden = false
    this.tileTarget.removeAttribute("aria-hidden")
  }
}
