import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: Number }

  connect() {
    // 自動的に消える
    this.timeout = setTimeout(() => {
      this.close()
    }, this.delayValue || 3000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close() {
    this.element.classList.remove("animate-slide-down")
    this.element.classList.add("animate-slide-up")
    
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}