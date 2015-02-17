require 'faraday'

module WpCache
  extend ActiveSupport::Concern

  # Class methods
  class << self
    # Collect all class names in a class variable so that it can be accessed by the rake task
    def included(base)
      @classes ||= []
      @classes << base.name
    end

    # Returns an array WpCache classes
    def classes
      @classes
    end
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

    def get_and_save_all(wpclass)
      response = Faraday.get "#{Settings.wordpress_url}/#{wpclass.pluralize.downcase}"
      wp_json = JSON.parse(response.body)
      ids = []
      wp_json.each do |json|
        self.where(id: json['ID']).first_or_create.update_wp_cache(json)
        ids << json['ID']
      end

      if !ids.empty?
        deleted_ids = self.where.not(id: ids)
        if !deleted_ids.empty?
          deleted_ids.each do |deleted_id|
            self.destroy(deleted_id)
          end
        end
      end

    end
  end
end
