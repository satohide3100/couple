import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  async connect() {
    const Sortable = await this.loadSortableJs()
    
    // デバッグ: 初期状態を確認
    const children = Array.from(this.element.children)
    console.log('Sortable初期化:', {
      container: this.element.id,
      childCount: children.length,
      childIds: children.map(child => child.dataset.sortableId || 'undefined')
    })
    
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      ghostClass: "opacity-50",
      dragClass: "shadow-2xl",
      handle: ".drag-handle",
      onEnd: this.handleDrop.bind(this)
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  async handleDrop(event) {
    const itemId = event.item.dataset.sortableId
    const newPosition = event.newIndex + 1
    
    console.log('並び替え開始:', {
      element: event.item.tagName,
      itemId,
      dataset: event.item.dataset,
      newPosition,
      oldPosition: event.oldIndex + 1
    })

    if (event.oldIndex === event.newIndex) {
      console.log("位置が変わっていません")
      return
    }

    try {
      const url = this.urlValue.replace(":id", itemId)
      console.log('リクエストURL:', url)
      
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ position: newPosition })
      })

      const responseData = await response.json()
      console.log('レスポンス:', response.status, response.ok ? '成功' : '失敗', responseData)

      if (!response.ok) {
        console.error('並び替え失敗:', responseData.message || 'Unknown error')
        window.location.reload()
      } else {
        console.log('並び替え成功！', responseData)
      }
    } catch (error) {
      console.error('エラー:', error)
      window.location.reload()
    }
  }

  async loadSortableJs() {
    if (window.Sortable) {
      return window.Sortable
    }
    
    // SortableJSを動的にロード
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/sortablejs@latest/Sortable.min.js'
      script.onload = () => resolve(window.Sortable)
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
}