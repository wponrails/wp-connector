Rails.application.routes.draw do
  resources :posts

  post 'wp-connector/post_save'
end
