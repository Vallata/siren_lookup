Rails.application.routes.draw do
  # get 'lookups/index'
  # get 'lookups/upload'
  # get 'lookups/process'
  # get 'lookups/download'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "rails/health#show", as: :rails_health_check
  root 'lookups#index'
  post '/upload', to: 'lookups#upload', as: :upload_lookups
  get '/result', to: 'lookups#result', as: :result_lookups

end
