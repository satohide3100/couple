import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  handleSubmit(event) {
    if (event.detail.success) {
      // Close any open modals
      const modals = document.querySelectorAll('.fixed.inset-0.z-50:not(.hidden)')
      modals.forEach(modal => {
        modal.classList.add('hidden')
      })
      document.body.classList.remove('overflow-hidden')
    }
  }
}