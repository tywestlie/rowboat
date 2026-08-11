import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_MS = 200
const BLUR_CLOSE_DELAY_MS = 100

export default class extends Controller {
  static targets = ["input", "menu", "allToggle"]
  static values = { hostsUrl: String }

  connect() {
    this.suggestions = []
    this.activeIndex = -1

    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    document.addEventListener("click", this.handleDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
    clearTimeout(this.debounceTimeout)
    clearTimeout(this.blurTimeout)
  }

  onInput() {
    clearTimeout(this.debounceTimeout)
    this.debounceTimeout = setTimeout(() => this.fetchSuggestions(), DEBOUNCE_MS)
  }

  async fetchSuggestions() {
    const query = this.inputTarget.value.trim()
    const includeAll = this.hasAllToggleTarget && this.allToggleTarget.checked ? "1" : "0"

    const url = new URL(this.hostsUrlValue, window.location.origin)
    url.searchParams.set("q", query)
    url.searchParams.set("all", includeAll)

    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) return

    this.suggestions = await response.json()
    this.renderMenu()
  }

  renderMenu() {
    this.menuTarget.replaceChildren()
    this.activeIndex = -1

    if (this.suggestions.length === 0) {
      this.menuTarget.classList.add("hidden")
      return
    }

    this.suggestions.forEach((suggestion, index) => {
      const item = document.createElement("li")
      const planetLabel = suggestion.planet_count === 1 ? "1 planet" : `${suggestion.planet_count} planets`
      item.textContent = `${suggestion.hostname} (${planetLabel})`
      item.dataset.index = index
      item.className = "cursor-pointer px-3 py-2 text-sm text-signal hover:bg-grid-line"
      item.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.navigateTo(suggestion.hostname)
      })
      this.menuTarget.appendChild(item)
    })

    this.menuTarget.classList.remove("hidden")
  }

  onKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      if (this.activeIndex >= 0 && this.suggestions[this.activeIndex]) {
        this.navigateTo(this.suggestions[this.activeIndex].hostname)
      } else if (this.inputTarget.value.trim() === "") {
        this.navigateTo(null)
      }
      return
    }

    if (this.menuTarget.classList.contains("hidden")) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveActive(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveActive(-1)
    } else if (event.key === "Escape") {
      this.menuTarget.classList.add("hidden")
    }
  }

  moveActive(delta) {
    const items = [ ...this.menuTarget.children ]
    if (items.length === 0) return

    items[this.activeIndex]?.classList.remove("bg-grid-line")
    this.activeIndex = (this.activeIndex + delta + items.length) % items.length
    items[this.activeIndex].classList.add("bg-grid-line")
    items[this.activeIndex].scrollIntoView({ block: "nearest" })
  }

  onBlur() {
    this.blurTimeout = setTimeout(() => this.menuTarget.classList.add("hidden"), BLUR_CLOSE_DELAY_MS)
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  navigateTo(hostname) {
    const url = new URL(window.location.href)

    if (hostname) {
      url.searchParams.set("hostname", hostname)
    } else {
      url.searchParams.delete("hostname")
    }
    url.searchParams.delete("page")

    if (window.Turbo) {
      window.Turbo.visit(url.toString())
    } else {
      window.location.href = url.toString()
    }
  }
}
