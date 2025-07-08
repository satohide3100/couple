import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: String }

  async connect() {
    console.log("LIFF Controller connected with ID:", this.idValue)
    
    try {
      // LIFF SDKを動的にロード
      console.log("Loading LIFF SDK...")
      const liff = await this.loadLiffSdk()
      console.log("LIFF SDK loaded:", liff)
      
      // LIFF 初期化
      console.log("Initializing LIFF with ID:", this.idValue)
      await liff.init({ liffId: this.idValue })
      console.log("LIFF initialized successfully")
      
      // LIFF環境かどうかを確認
      const isInClient = liff.isInClient()
      const isLoggedIn = liff.isLoggedIn()
      console.log("isInClient:", isInClient, "isLoggedIn:", isLoggedIn)
      
      if (isInClient) {
        // LIFF環境の場合、ログインボタンを非表示にして自動ログイン
        console.log("In LIFF client, hiding login button")
        this.hideLiffLoginButton()
        
        if (!isLoggedIn) {
          console.log("Not logged in, attempting LIFF login...")
          // LIFF環境では自動的にログイン
          await liff.login()
          return
        }

        console.log("Getting user profile...")
        // プロフィール取得とセッション作成
        const profile = await liff.getProfile()
        console.log("Profile obtained:", profile)
        
        console.log("Creating session...")
        await this.createSession(profile.userId)
        
        // CSRF トークンの設定
        this.setupCsrfToken()
      } else {
        // ブラウザ環境の場合、ログインボタンを表示
        console.log("Not in LIFF client, showing login button")
        this.showLiffLoginButton()
      }
    } catch (error) {
      console.error("LIFF initialization failed:", error)
      this.showErrorMessage(error.message)
      // エラーの場合はログインボタンを表示
      this.showLiffLoginButton()
    }
  }

  async createSession(userId) {
    console.log("Creating session for userId:", userId)
    
    try {
      const response = await fetch("/session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ liff_user_id: userId })
      })

      console.log("Session response:", response.status, response.statusText)
      
      if (response.ok) {
        console.log("Session created successfully, redirecting to dashboard...")
        window.location.href = "/dashboard"
      } else {
        const errorText = await response.text()
        console.error("Session creation failed:", errorText)
        this.showErrorMessage("セッション作成に失敗しました")
      }
    } catch (error) {
      console.error("Session creation error:", error)
      this.showErrorMessage("ネットワークエラーが発生しました")
    }
  }

  setupCsrfToken() {
    // Ajaxリクエストに LIFF ID トークンを追加
    document.addEventListener("turbo:before-fetch-request", async (event) => {
      const token = await liff.getIDToken()
      event.detail.fetchOptions.headers["X-LIFF-Token"] = token
    })
  }

  async login() {
    liff.login()
  }

  async logout() {
    const liff = await this.loadLiffSdk()
    liff.logout()
    window.location.href = "/session/new"
  }

  hideLiffLoginButton() {
    const loginButton = document.querySelector('[data-action="click->liff#login"]')
    if (loginButton) {
      loginButton.style.display = 'none'
    }
    
    // ローディング表示を追加
    const container = document.querySelector('.space-y-4')
    if (container) {
      container.innerHTML = `
        <div class="flex items-center justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
          <span class="ml-3 text-gray-600">LINEアカウントで認証中...</span>
        </div>
      `
    }
  }

  showLiffLoginButton() {
    const loginButton = document.querySelector('[data-action="click->liff#login"]')
    if (loginButton) {
      loginButton.style.display = 'flex'
    }
    
    // ローディング表示を削除
    const container = document.querySelector('.space-y-4')
    if (container && container.innerHTML.includes('animate-spin')) {
      location.reload()
    }
  }

  showErrorMessage(message) {
    const container = document.querySelector('.space-y-4')
    if (container) {
      container.innerHTML = `
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg">
          <p class="font-medium">エラーが発生しました</p>
          <p class="text-sm">${message}</p>
        </div>
        <button onclick="location.reload()" 
                class="w-full bg-gray-500 hover:bg-gray-600 text-white font-bold py-3 px-4 rounded-lg transition">
          再試行
        </button>
      `
    }
  }

  async loadLiffSdk() {
    if (window.liff) {
      return window.liff
    }
    
    // LIFF SDKを動的にロード
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://static.line-scdn.net/liff/edge/2/sdk.js'
      script.onload = () => resolve(window.liff)
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
}