import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  connect() {
    // Listen for custom close events
    document.addEventListener("modal-close", this.handleCloseEvent.bind(this))
  }

  disconnect() {
    document.removeEventListener("modal-close", this.handleCloseEvent.bind(this))
  }

  handleCloseEvent(event) {
    this.close()
  }

  open(event) {
    event.preventDefault()
    const modalId = this.targetValue || event.currentTarget.dataset.modalTargetValue
    const modal = document.getElementById(modalId)
    
    if (modal) {
      modal.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }
  }

  close(event) {
    if (event) event.preventDefault()
    const modal = this.element
    modal.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  scrollToForm() {
    const form = document.getElementById("place_form")
    if (form) {
      form.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }
}