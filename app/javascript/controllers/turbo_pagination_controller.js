import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { frame: String }

  connect() {
    // Add turbo-frame data attribute to all pagination links
    const links = this.element.querySelectorAll('a')
    links.forEach(link => {
      link.setAttribute('data-turbo-frame', this.frameValue)
    })
  }
}
