export const TaskSortable = {
  mounted() {
    this.container = this.el
    this.dragging = null
    this.draggingType = null // "task" or "subtask"

    this.container.addEventListener("mousedown", e => {
      const item = e.target.closest("[data-task-id]")
      if (!item) return

      const isHandle = !!e.target.closest("[data-handle]")
      const isSubtaskHandle = !!e.target.closest("[data-subtask-handle]")

      if (isHandle) {
        item.setAttribute("draggable", "true")
      } else if (isSubtaskHandle) {
        item.setAttribute("draggable", "true")
      } else {
        item.setAttribute("draggable", "false")
      }
    })

    this.container.addEventListener("dragstart", e => {
      const item = e.target.closest("[data-task-id]")
      if (!item || item.getAttribute("draggable") !== "true") return

      const isSubtask = !!item.dataset.subtaskOf

      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", item.dataset.taskId)

      this.dragging = item
      this.draggingType = isSubtask ? "subtask" : "task"
      item.classList.add("opacity-50")

      if (!isSubtask) {
        this.getSubtasks(item).forEach(s => s.classList.add("opacity-50"))
      }
    })

    this.container.addEventListener("dragend", e => {
      const item = e.target.closest("[data-task-id]")
      if (!item) return

      item.classList.remove("opacity-50")
      this.getSubtasks(item).forEach(s => s.classList.remove("opacity-50"))
      item.setAttribute("draggable", this.draggingType === "subtask" ? "false" : "true")
      this.dragging = null
      this.draggingType = null
    })

    this.container.addEventListener("dragover", e => {
      const dragging = this.dragging
      if (!dragging) return

      const target = e.target.closest("[data-task-id]")
      if (!target || target === dragging) return

      e.preventDefault()
      e.dataTransfer.dropEffect = "move"

      if (this.draggingType === "subtask") {
        // Only allow reordering within the same parent
        if (target.dataset.subtaskOf !== dragging.dataset.subtaskOf) return

        const targetRect = target.getBoundingClientRect()
        const before = e.clientY < targetRect.top + targetRect.height / 2

        if (before) {
          target.parentNode.insertBefore(dragging, target)
        } else {
          target.parentNode.insertBefore(dragging, target.nextSibling)
        }
      } else {
        // Parent task: only drop on other parent tasks
        if (target.getAttribute("draggable") !== "true" || target.dataset.subtaskOf) return

        const targetRect = target.getBoundingClientRect()
        const before = e.clientY < targetRect.top + targetRect.height / 2

        const draggingSubtasks = this.getSubtasks(dragging)
        const targetSubtasks = this.getSubtasks(target)
        const anchor = before ? target : (targetSubtasks.at(-1) || target)

        if (before) {
          anchor.parentNode.insertBefore(dragging, anchor)
          draggingSubtasks.forEach(s => anchor.parentNode.insertBefore(s, anchor))
        } else {
          const afterAnchor = anchor.nextSibling
          anchor.parentNode.insertBefore(dragging, afterAnchor)
          draggingSubtasks.forEach(s => anchor.parentNode.insertBefore(s, afterAnchor))
        }
      }
    })

    this.container.addEventListener("drop", e => {
      const draggedId = e.dataTransfer.getData("text/plain")
      if (!draggedId) return

      e.preventDefault()

      if (this.draggingType === "subtask") {
        this.pushSubtaskOrder(this.dragging)
      } else {
        this.pushTaskOrder()
      }
    })
  },

  getSubtasks(item) {
    const taskId = item.dataset.taskId
    if (!taskId) return []
    return Array.from(
      this.container.querySelectorAll(`[data-subtask-of='${taskId}']`)
    )
  },

  pushTaskOrder() {
    const ids = Array.from(this.container.querySelectorAll("[data-task-id]"))
      .filter(el => !el.dataset.subtaskOf)
      .map(el => el.dataset.taskId)

    this.pushEvent("tasks_reorder", { ids })
  },

  pushSubtaskOrder(dragging) {
    const parentId = dragging.dataset.subtaskOf
    const ids = Array.from(
      this.container.querySelectorAll(`[data-subtask-of='${parentId}']`)
    ).map(el => el.dataset.taskId)

    this.pushEvent("subtasks_reorder", { parent_id: parentId, ids })
  },
}
