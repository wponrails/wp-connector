require 'faraday'

module WpCache
  extend ActiveSupport::Concern

  module ClassMethods

    #
    # Collect all class names in a class variable so that it can be accessed by the Rake task.
    #
    def included(base)
      @classes ||= []
      @classes << base.name
    end

    #
    # Returns an array WpCache classes.
    #
    def classes
      @classes
    end

    #
    # Schedules a `create_or_update` call to itself.
    #
    def schedule_create_or_update(wp_id)
      WpApiWorker.perform_async(self, wp_id)
    end

    #
    # Gets the content from the WP API, finds-or-creates a record for it,
    # and passes it the content by the `update_wp_cache` instance method.
    #
    def create_or_update(wp_type, wp_id)
      return unless wp_id.is_a? Fixnum or wp_id.is_a? String
      response = Faraday.get "#{ Rails.configuration.x.wordpress_url }?json_route=/#{ wp_type }/#{ wp_id }"
      wp_json = JSON.parse(response.body)
      #WP API will return a 'json_no_route' code if the route is incorrect or the specified entry is none existant
      #If so, do not 'first_or_create'
      return if wp_json["code"] == "json_no_route"
      where(wp_id: wp_id).first_or_create.update_wp_cache(wp_json)
    end

    #
    # Gets all WP IDs for a class of WP content form the WP API,
    # finds-or-creates a record for it, and passes it the content by
    # the `update_wp_cache` instance method.
    # Removes records with unknown IDs.
    #
    def create_or_update_all(wp_class)
      response = Faraday.get "#{ Rails.configuration.x.wordpress_url }?json_route=/#{ wp_class.pluralize.downcase }"
      wp_json = JSON.parse(response.body)
      ids = []
      wp_json.each do |json|
        find(wp_id).first_or_create.update_wp_cache(json)
        ids << json['ID']
      end
      where('wp_id NOT IN (?)', ids).destroy_all unless ids.empty?
    end

    #
    # Purge a cached piece of content, while logging any exceptions.
    #
    def purge(wp_id)
      where(wp_id: wp_id).first!.destroy
    rescue
      logger.warn "Could not purge #{self} with id #{wp_id}, no record with that id was found."
    end
  end
end
