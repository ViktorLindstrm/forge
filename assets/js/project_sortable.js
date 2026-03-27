export const ProjectSortable = {
  mounted() {
    this.dragging = null
    this.dragged = false

    this.el.addEventListener("dragstart", e => {
      const card = e.target.closest("[data-project-id]")
      if (!card || !e.dataTransfer) return
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", card.dataset.projectId)
      this.dragging = card
      this.dragged = false
      setTimeout(() => card.classList.add("opacity-40"), 0)
    })

    this.el.addEventListener("dragend", e => {
      const card = e.target.closest("[data-project-id]")
      if (card) card.classList.remove("opacity-40")
      this.dragging = null
    })

    this.el.addEventListener("dragover", e => {
      if (!this.dragging) return
      const target = e.target.closest("[data-project-id]")
      if (!target || target === this.dragging) return
      e.preventDefault()
      e.dataTransfer.dropEffect = "move"
      this.dragged = true

      const rect = target.getBoundingClientRect()
      if (e.clientX < rect.left + rect.width / 2) {
        target.parentNode.insertBefore(this.dragging, target)
      } else {
        target.parentNode.insertBefore(this.dragging, target.nextSibling)
      }
    })

    this.el.addEventListener("drop", e => {
      const draggedId = e.dataTransfer.getData("text/plain")
      if (!draggedId) return
      e.preventDefault()
      this.pushOrder()
    })

    // Block LiveView navigation click if a drag just happened
    this.el.addEventListener("click", e => {
      if (this.dragged) {
        e.preventDefault()
        e.stopImmediatePropagation()
        this.dragged = false
      }
    }, true)
  },

  pushOrder() {
    const ids = Array.from(this.el.querySelectorAll("[data-project-id]")).map(
      el => el.dataset.projectId
    )
    this.pushEvent("projects_reorder", { group_id: this.el.dataset.groupId, ids })
  }
}
