Rails.application.routes.draw do
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # Active Storage routes for file serving in production
  if Rails.env.production?
    get "/rails/active_storage/blobs/:signed_id/*filename" => "active_storage/blobs#show"
    get "/rails/active_storage/representations/:signed_blob_id/:variation_key/*filename" => "active_storage/representations#show"
  end

  # ルート - ログイン後はダッシュボードにリダイレクト
  root "sessions#new"

  # セッション管理
  resource :session, only: [:new, :create, :destroy]

  # メインダッシュボード（タブベース）
  get "dashboard", to: "dashboard#index"
  get "dashboard/:category_id", to: "dashboard#show", as: :dashboard_category

  # 記念日カウント
  get "anniversary", to: "anniversary#index"
  patch "anniversary", to: "anniversary#update"

  # カテゴリーと場所（API風）
  resources :categories, only: [:index, :create, :update, :destroy] do
    member do
      patch :move
    end
  end
  resources :places, only: [:create, :update, :destroy] do
    member do
      patch :toggle_visited
      patch :move
    end
  end
end
