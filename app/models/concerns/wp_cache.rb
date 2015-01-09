require 'faraday'

module WpCache
  extend ActiveSupport::Concern

  def self.included(base)
    @classes ||= []
    @classes << base.name
  end

  def self.classes
    @classes
  end

  module ClassMethods
    def sync_cache(wp_type, wp_id)
      WpGetWorker.perform_async(self, wp_type, wp_id)
    end
  
    def purge_cache(wp_id)
      m = self.find(wp_id)
      if m
        m.destroy
      else
        logger.warn "Could not find #{self} with id #{wp_id}."
      end
    end
    
    def retrieve_and_update_wp_cache(wp_type, wp_id)
      response = Faraday.get "#{Settings.wordpress_url}/#{wp_type}/#{wp_id}"
      wp_json = JSON.parse(response.body)
      self.where(id: wp_id).first_or_create.update_wp_cache(wp_json)
    end

    def get_and_save_all
      response = Faraday.get "#{Settings.wordpress_url}/#{WpCache.classes.first.pluralize.downcase}"
      wp_json = JSON.parse(response.body)
      wp_json.each do |json|
        # self.where(id: wp_id).first_or_create.update_wp_cache(json)
      end
    end
  end
end
