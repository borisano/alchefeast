import { Controller } from "@hotwired/stimulus"
import { get } from '@rails/request.js'

export default class extends Controller {
  connect() {
    // Add turbo stream handling to all pagination links within this controller
    this.element.querySelectorAll('a[href*="page="]').forEach(link => {
      link.addEventListener('click', this.getTurboStream.bind(this))
    })
  }

  getTurboStream(event) {
    event.preventDefault()
    get(event.target.href, {
      contentType: "text/vnd.turbo-stream.html",
      responseKind: "turbo-stream"
    })
  }

  submitForm(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    const url = new URL(form.action)
    
    // Add form data to URL as query parameters
    for (const [key, value] of formData.entries()) {
      if (value) {
        url.searchParams.set(key, value)
      }
    }

    get(url.toString(), {
      contentType: "text/vnd.turbo-stream.html",
      responseKind: "turbo-stream"
    })
  }
}
