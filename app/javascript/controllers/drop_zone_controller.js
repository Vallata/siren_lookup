import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "zone"]

  connect() {
    this.zoneTarget.addEventListener("click", () => this.inputTarget.click())

    this.zoneTarget.addEventListener("dragover", (e) => {
      e.preventDefault()
      this.zoneTarget.classList.add("bg-blue-50")
    })

    this.zoneTarget.addEventListener("dragleave", () => {
      this.zoneTarget.classList.remove("bg-blue-50")
    })

    this.zoneTarget.addEventListener("drop", (e) => {
      e.preventDefault()
      this.zoneTarget.classList.remove("bg-blue-50")
      const files = e.dataTransfer.files
      this.inputTarget.files = files
    })
  }
}

