Rails.application.routes.draw do
  mount Peek::Railtie => '/peek'
  resources :subscriptions

  namespace :admin do
    mount RedisBrowser::Web => '/redis-browser'
    mount ResqueWeb::Engine => "/resque_web"
    get :resque, to: 'application#resque'
  end

  root :to => "subscriptions#index"


  namespace :api do
    namespace :v1 do
      resources :subscriptions
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
