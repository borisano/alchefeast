import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop"]

  connect() {
    console.log("Recipe modal controller connected!")
    
    // Show the modal with animation
    if (this.hasModalTarget) {
      // Prevent body scrolling when modal is open
      document.body.style.overflow = 'hidden'
      
      // Add animation class
      this.modalTarget.style.transform = 'translateX(100%)'
      requestAnimationFrame(() => {
        this.modalTarget.style.transform = 'translateX(0)'
      })

      // Handle ESC key
      this.boundHandleKeydown = this.handleKeydown.bind(this)
      document.addEventListener('keydown', this.boundHandleKeydown)
      
      console.log("Modal initialized successfully")
    }
  }

  disconnect() {
    console.log("Recipe modal controller disconnected")
    
    // Remove event listener and restore scrolling
    if (this.boundHandleKeydown) {
      document.removeEventListener('keydown', this.boundHandleKeydown)
    }
    document.body.style.overflow = ''
  }

  handleKeydown(event) {
    // Close modal on ESC key
    if (event.key === 'Escape') {
      console.log("ESC key pressed - closing modal")
      this.close(event)
    }
  }

  close(event) {
    console.log("Close method called", event)
    
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    // Animate modal out
    if (this.hasModalTarget) {
      this.modalTarget.style.transform = 'translateX(100%)'
      
      // Clear modal content after animation
      setTimeout(() => {
        this.clearModal()
      }, 300)
    } else {
      this.clearModal()
    }
  }

  clearModal() {
    console.log("Clearing modal content")
    
    // Clear the modal content when closed
    this.element.innerHTML = ""
    
    // Restore body scrolling
    document.body.style.overflow = ''
  }
}
