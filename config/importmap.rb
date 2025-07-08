# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# LIFF SDK
pin "@line/liff", to: "https://static.line-scdn.net/liff/edge/2/sdk.js"

# Sortable.js
pin "sortablejs", to: "https://cdn.skypack.dev/sortablejs"
