namespace :wp do
  namespace :cache do
    desc "Load all objects from Wordpress"
    task refresh: :environment do
      WpCache.classes.each do |wp_cache_class|
        wp_cache_class.constantize.create_or_update_all
      end
    end
  end
end
