import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Initialize Bootstrap offcanvas when modal loads
    if (this.hasModalTarget) {
      this.offcanvas = new bootstrap.Offcanvas(this.modalTarget)
      this.offcanvas.show()
      
      // Handle close events
      this.modalTarget.addEventListener('hidden.bs.offcanvas', () => {
        this.clearModal()
      })
    }
  }

  disconnect() {
    if (this.offcanvas) {
      this.offcanvas.dispose()
    }
  }

  clearModal() {
    // Clear the modal content when closed
    this.element.innerHTML = ""
  }

  close() {
    if (this.offcanvas) {
      this.offcanvas.hide()
    }
  }
}
