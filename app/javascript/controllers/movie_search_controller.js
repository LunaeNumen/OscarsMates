import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "clearBtn"]

  connect() {
    this.toggleClearButton()
  }

  toggleClearButton() {
    if (this.hasClearBtnTarget) {
      const hasValue = this.inputTarget.value.length > 0
      this.clearBtnTarget.style.display = hasValue ? 'flex' : 'none'
    }

    // If input is cleared, submit the form to show all results
    if (this.inputTarget.value === '') {
      this.inputTarget.form.submit()
    }
  }

  clear(event) {
    event.preventDefault()
    event.stopPropagation()

    // Clear the input
    this.inputTarget.value = ''

    // Hide the clear button
    if (this.hasClearBtnTarget) {
      this.clearBtnTarget.style.display = 'none'
    }

    // Submit the form to reload without query parameter
    this.inputTarget.form.submit()
  }
}
