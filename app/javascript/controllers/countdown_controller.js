import { Controller } from "@hotwired/stimulus"

// Counts down to data-countdown-deadline-value (ISO 8601). The server
// renders the starting values, so the page is right without JavaScript.
export default class extends Controller {
  static targets = ["hours", "minutes", "seconds"]
  static values = { deadline: String }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const remaining = Math.max(0, Date.parse(this.deadlineValue) - Date.now())
    const totalSeconds = Math.floor(remaining / 1000)

    this.hoursTarget.textContent = this.pad(Math.floor(totalSeconds / 3600))
    this.minutesTarget.textContent = this.pad(Math.floor((totalSeconds % 3600) / 60))
    this.secondsTarget.textContent = this.pad(totalSeconds % 60)

    if (remaining === 0) clearInterval(this.timer)
  }

  pad(number) {
    return String(number).padStart(2, "0")
  }
}
