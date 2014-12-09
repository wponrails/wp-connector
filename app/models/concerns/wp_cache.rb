require 'faraday'

module WpCache
  extend ActiveSupport::Concern

  module ClassMethods
    def retrieve_and_update_wp_cache(wp_type, wp_id)
      response = Faraday.get "#{Settings.wordpress_url}/#{wp_type}/#{wp_id}"
      wp_json = JSON.parse(response.body)
      self.find_or_create(wp_id).update_wp_cache(wp_json)
    end
  end
end
