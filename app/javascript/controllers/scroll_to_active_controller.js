import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 初回実行
    setTimeout(() => {
      this.scrollToActive()
    }, 500)
    
    // DOMContentLoadedイベントで実行
    document.addEventListener('DOMContentLoaded', () => {
      setTimeout(() => this.scrollToActive(), 300)
    })
    
    // ページロード時に実行
    window.addEventListener('load', () => {
      setTimeout(() => this.scrollToActive(), 300)
    })
    
    // クリックイベントを監視
    this.element.addEventListener('click', (event) => {
      setTimeout(() => {
        this.scrollToActive()
      }, 100)
    })
  }
  
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  scheduleScroll() {
    // 即座に実行
    this.scrollToActive()
    
    // 少し遅延を入れて再実行
    setTimeout(() => this.scrollToActive(), 50)
    setTimeout(() => this.scrollToActive(), 150)
    setTimeout(() => this.scrollToActive(), 300)
  }

  scrollToActive() {
    // アクティブなタブを探す
    const activeTab = this.element.querySelector('.bg-blue-500')
    
    if (!activeTab) {
      return
    }
    
    // アクティブなタブのコンテナを取得
    const container = activeTab.closest('[id^="category_tab_"]')
    
    if (!container) {
      return
    }
    
    // scrollIntoViewを使用してアクティブなタブを左側に表示
    container.scrollIntoView({ 
      behavior: 'smooth', 
      block: 'nearest', 
      inline: 'start' 
    })
  }
}