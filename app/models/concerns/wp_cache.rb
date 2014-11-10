module WpCache
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    def get_from_wp(type, wp_id)
      response = Faraday.get "#{Settings.wordpress_url}/#{type.to_s}/#{wp_id.to_s}"
      parsed_response = JSON.parse(response.body)
    end
  end
end
