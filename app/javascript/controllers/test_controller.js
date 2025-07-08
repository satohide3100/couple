import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const debugContent = document.getElementById('debug-content')
    if (debugContent) {
      const logEntry = document.createElement('div')
      logEntry.textContent = 'Test controller connected!'
      debugContent.appendChild(logEntry)
    }
  }
}