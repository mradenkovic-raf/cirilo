Rails.application.routes.draw do
  root "dashboard#index"
  get "/adventure", to: "adventures#show", as: :adventure
  get "/workshop", to: "dashboard#workshop", as: :workshop
  post "/workshop/egg", to: "eggs#create", as: :egg_workshop
  post "/workshop/egg/hatch", to: "eggs#hatch", as: :hatch_egg_workshop
  patch "/workshop/egg/name", to: "eggs#name", as: :name_egg_workshop
  patch "/workshop", to: "dashboard#customize", as: :customize_workshop
  post "/workshop/reset-dino", to: "dashboard#reset_dino", as: :reset_dino_workshop
  post "/workshop/restore-dino", to: "dashboard#restore_dino", as: :restore_dino_workshop
  get "/alphabet", to: "dashboard#alphabet", as: :alphabet
  get "/progress", to: "dashboard#progress", as: :progress
  patch "/progress/learning", to: "learning_settings#update", as: :learning_settings
  post "/progress/reset-shop", to: "shop#reset", as: :reset_shop_progress
  post "/progress/reset-all", to: "full_resets#create", as: :reset_all_progress
  get "/shop", to: "shop#index", as: :shop
  post "/shop/purchases", to: "shop#create", as: :shop_purchases
  patch "/shop/equip", to: "shop#equip", as: :equip_shop
  resources :practice_sessions, only: [:create, :show] do
    post :memorize, on: :member
    resources :attempts, only: [:create]
    resource :battle, only: [:create]
  end
  resources :battles, only: [:show]
  post "/battles/:id/moves", to: "battles#move", as: :battle_moves
  post "/battles/:id/powers", to: "battles#power", as: :power_battle
  get "up" => "rails/health#show", as: :rails_health_check
end
