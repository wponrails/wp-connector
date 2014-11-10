Rails.application.routes.draw do
  resources :posts
  
  post 'wpep/post_save'

end
