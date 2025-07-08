Rails.application.routes.draw do
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check


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
  
  # アップロードされたファイルの配信（本番環境用）
  if Rails.env.production?
    get '/uploads/*path', to: 'application#serve_file'
  end
end