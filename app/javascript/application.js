// Turbo と Stimulus の設定
import "@hotwired/turbo-rails"
import "./controllers"

// Turbo設定（LIFF環境での調整）
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = true
Turbo.setFormMode("optin")
