import { Controller } from "@hotwired/stimulus"

// A -/number/+ quantity stepper capped at data-quantity-stepper-max-value
// (already computed server-side as min(stock, 10)).
export default class extends Controller {
  static targets = ["input", "increment", "decrement"]
  static values = { max: Number }

  connect() {
    this.render()
  }

  increment() {
    if (this.currentValue >= this.maxValue) return
    this.inputTarget.value = this.currentValue + 1
    this.render()
  }

  decrement() {
    if (this.currentValue <= 1) return
    this.inputTarget.value = this.currentValue - 1
    this.render()
  }

  render() {
    this.incrementTarget.disabled = this.currentValue >= this.maxValue
    this.decrementTarget.disabled = this.currentValue <= 1
  }

  get currentValue() {
    return parseInt(this.inputTarget.value, 10) || 1
  }
}
