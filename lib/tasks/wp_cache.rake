namespace :wp do
  namespace :cache do
    desc "Load all objects from Wordpress"
    task :refresh => :environment do
      Rails.application.eager_load!
      ActiveRecord::Base.descendants
      
      first = WpCache.classes.first.constantize
      wp_json = first.get_and_save_all
    end
  end
end