require 'faraday'

module WpCache
  extend ActiveSupport::Concern

  module ClassMethods
    def get_from_wp(type, wp_id)
      response = Faraday.get "#{Settings.wordpress_url}/#{type.to_s}/#{wp_id.to_s}"
      parsed_response = JSON.parse(response.body)
    end

    def on_save(wp_id, object)
      wp_json = get_from_wp(object, wp_id)
      if o = object.classify.constantize.where('id= ?', wp_id).first
        o.from_wp_json(wp_json)
      else
        o = object.classify.constantize.new
        o.from_wp_json(wp_json)
      end
      o.save!
    end
  end
end
