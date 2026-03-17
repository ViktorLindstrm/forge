// assets/js/hooks.js

export let Hooks = {}

// ── SortableTasks ────────────────────────────────────────────────────────────

Hooks.SortableTasks = {
  mounted() {
    const Sortable = window.Sortable
    if (!Sortable) {
      console.error("Sortable not found — kontrollera att assets/vendor/sortable.js laddas")
      return
    }
    this.sorter = new Sortable(this.el, {
      handle: "[data-drag-handle]",
      animation: 150,
      onEnd: () => {
        const ids = [...this.el.querySelectorAll("[data-task-id]")]
          .map(el => el.dataset.taskId)
        this.pushEvent("reorder_tasks", { ids })
      }
    })
  },
  destroyed() { this.sorter?.destroy() }
}

// ── ChipInput ────────────────────────────────────────────────────────────────
// Förväntar sig:
//   data-hidden-input  = id på det dolda input-fältet som skickas med formuläret
//   data-initial-tags  = kommaseparerad sträng med befintliga taggar

Hooks.ChipInput = {
  mounted() {
    this.tags   = this.parseTags(this.el.dataset.initialTags || "")
    this.mdMode = false
    this.render()
  },

  parseTags(str) {
    return str.split(",").map(s => s.trim()).filter(Boolean)
  },

  syncHidden() {
    const id = this.el.dataset.hiddenInput
    const el = document.getElementById(id)
    if (el) el.value = this.tags.join(",")
  },

  addTag(name) {
    const clean = name.trim().toLowerCase()
    if (clean && !this.tags.includes(clean)) {
      this.tags.push(clean)
      this.syncHidden()
      this.render()
    }
  },

  removeTag(name) {
    this.tags = this.tags.filter(t => t !== name)
    this.syncHidden()
    this.render()
  },

  toggleMode() {
    this.mdMode = !this.mdMode
    this.render()
    if (this.mdMode) {
      const ta = this.el.querySelector("textarea")
      if (ta) { ta.focus(); ta.selectionStart = ta.value.length }
    } else {
      const input = this.el.querySelector("input[type=text]")
      if (input) input.focus()
    }
  },

  render() {
    const hiddenId = this.el.dataset.hiddenInput
    const placeholder = this.el.dataset.placeholder || "Lägg till tagg..."

    if (this.mdMode) {
      this.el.innerHTML = `
        <div class="flex items-center gap-2">
          <textarea
            class="flex-1 text-xs border border-zinc-200 rounded px-2 py-1 font-mono
                   bg-zinc-50 outline-none focus:border-zinc-400 resize-none h-7 leading-5"
            placeholder="esphome, petg, uart"
          >${this.tags.join(", ")}</textarea>
          <button type="button"
            class="text-xs text-zinc-400 hover:text-zinc-600 whitespace-nowrap border
                   border-zinc-200 rounded px-1.5 py-0.5 hover:border-zinc-300">
            chips
          </button>
        </div>`

      const ta = this.el.querySelector("textarea")
      const btn = this.el.querySelector("button")

      ta.addEventListener("input", () => {
        this.tags = this.parseTags(ta.value)
        this.syncHidden()
      })
      btn.addEventListener("click", () => this.toggleMode())

    } else {
      const chips = this.tags.map(t =>
        `<span class="inline-flex items-center gap-1 bg-zinc-100 text-zinc-600
                      text-xs px-2 py-0.5 rounded-full border border-zinc-200">
          ${t}
          <button type="button" data-tag="${t}"
            class="text-zinc-400 hover:text-zinc-700 leading-none">×</button>
        </span>`
      ).join("")

      this.el.innerHTML = `
        <div class="flex flex-wrap items-center gap-1.5 min-h-[28px]">
          ${chips}
          <input type="text"
            class="text-xs border-0 outline-none bg-transparent
                   text-zinc-700 placeholder-zinc-400 min-w-[120px]"
            placeholder="${placeholder}" />
          <button type="button"
            class="text-xs text-zinc-300 hover:text-zinc-500 ml-auto whitespace-nowrap">
            markdown
          </button>
        </div>`

      const input = this.el.querySelector("input[type=text]")
      const mdBtn = this.el.querySelector("button:last-child")

      input.addEventListener("keydown", e => {
        if ((e.key === "," || e.key === "Enter" || e.key === " ") && input.value.trim()) {
          e.preventDefault()
          this.addTag(input.value.replace(",", ""))
        }
        if (e.key === "Backspace" && !input.value && this.tags.length) {
          this.removeTag(this.tags[this.tags.length - 1])
        }
      })

      this.el.querySelectorAll("[data-tag]").forEach(btn => {
        btn.addEventListener("click", () => this.removeTag(btn.dataset.tag))
      })

      mdBtn.addEventListener("click", () => this.toggleMode())
    }
  }
}
