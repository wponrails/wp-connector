require 'faraday'

module WpCache
  extend ActiveSupport::Concern

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
      self.find_or_create(wp_id).update_wp_cache(wp_json)
    end
  end
end
