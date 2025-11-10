Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  get "/health", to: "health#index"
  
  namespace :auth do
    post "/register", to: "auth#register"
    post "/login", to: "auth#login"
    post "/logout", to: "auth#logout"
    post "/refresh", to: "auth#refresh"
    get  "/me", to: "auth#me"
  end

  namespace :conversations do
    get "/", to: "conversations#get_all"
    post "/", to: "conversations#create"
    get "/:id", to: "conversations#get_by_id"
    get "/:conversation_id/messages", to: "conversations#get_all_by_id"
  end

  namespace :messages do
    post "/", to: "messages#create"
    put "/:id/read", to: "messages#mark_read"
  end

  namespace :expert do
    get "/queue", to: "expert#get_queue"
    post "/conversations/:conversation_id/claim", to: "expert#claim"
    post "/conversations/:conversation_id/unclaim", to: "expert#unclaim"
    get "/profile", to: "expert#get_profile"
    put "/profile", to: "expert#update_profile"
    get "/assignments/history", to: "expert#assignment_history"
  end

  namespace :api do
    get "/conversations/updates", to: "updates#conversations"
    get "/messages/updates",      to: "updates#messages"
    get "/expert-queue/updates",  to: "updates#expert_queue"
  end


end
