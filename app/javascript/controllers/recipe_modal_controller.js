import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop"]

  connect() {
    // Prevent body scrolling when modal is open
    document.body.style.overflow = 'hidden'
    
    // Add ESC key listener
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
    
    // Add smooth slide-in animation
    if (this.hasModalTarget) {
      this.modalTarget.style.transform = 'translateX(100%)'
      requestAnimationFrame(() => {
        this.modalTarget.style.transform = 'translateX(0)'
      })
    }
  }

  disconnect() {
    // Remove ESC key listener and restore scrolling
    if (this.boundHandleKeydown) {
      document.removeEventListener('keydown', this.boundHandleKeydown)
    }
    document.body.style.overflow = ''
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close(event)
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    // Animate slide-out if modal target exists
    if (this.hasModalTarget) {
      this.modalTarget.style.transform = 'translateX(100%)'
      
      // Clear content after 1-second animation completes
      setTimeout(() => {
        this.clearModal()
      }, 1000)
    } else {
      this.clearModal()
    }
  }

  clearModal() {
    // Clear the modal content and restore body scrolling
    this.element.innerHTML = ""
    document.body.style.overflow = ''
  }
}
