import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "clearBtn"]

  connect() {
    if (this.hasClearBtnTarget) {
      this.clearBtnTarget.style.display = this.inputTarget.value.length > 0 ? 'flex' : 'none'
    }
  }

  onInput() {
    const value = this.inputTarget.value

    if (this.hasClearBtnTarget) {
      this.clearBtnTarget.style.display = value.length > 0 ? 'flex' : 'none'
    }

    clearTimeout(this.searchTimeout)

    if (value === '') {
      this.navigateClear()
    } else if (value.length >= 3) {
      this.searchTimeout = setTimeout(() => this.navigateSearch(), 300)
    }
  }

  clear(event) {
    event.preventDefault()
    clearTimeout(this.searchTimeout)
    this.inputTarget.value = ''
    if (this.hasClearBtnTarget) {
      this.clearBtnTarget.style.display = 'none'
    }
    this.navigateClear()
  }

  navigateSearch() {
    const url = new URL(window.location.href)
    url.searchParams.set('query', this.inputTarget.value)
    window.location.href = url.toString()
  }

  navigateClear() {
    const url = new URL(window.location.href)
    if (url.searchParams.has('query')) {
      url.searchParams.delete('query')
      window.location.href = url.toString()
    }
  }
}
