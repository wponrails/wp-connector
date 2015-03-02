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
    # TODO (cies): add a configurable amount of delay, defaulting to 0.5secs
    def schedule_create_or_update(wp_id)
      WpApiWorker.perform_async(self, wp_id)
    end

    #
    # Gets the content from the WP API, finds-or-creates a record for it,
    # and passes it the content by the `update_wp_cache` instance method.
    #
    def create_or_update(wp_type, wp_id)
      return unless wp_id.is_a? Fixnum or wp_id.is_a? String
      wp_json = get_from_wp_api "#{ wp_type }/#{ wp_id }"
      # WP API will return a code if the route is incorrect or
      # the specified entry is none existant. If so return early.
      return if wp_json[0] and invalid_api_responses.include? wp_json[0]["code"]
      where(wp_id: wp_id).first_or_initialize.update_wp_cache(wp_json)
    end

    #
    # Gets all WP IDs for a class of WP content form the WP API,
    # finds-or-creates a record for it, and passes it the content by
    # the `update_wp_cache` instance method.
    # Removes records with unknown IDs.
    #
    def create_or_update_all
      wp_json = get_from_wp_api self.to_s.underscore.pluralize
      ids = wp_json.map do |json|
        wp_id = json['ID']
        where(wp_id: wp_id).first_or_initialize.update_wp_cache(json)
        wp_id
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

    private

    #
    # Convenience method for calling the WP API.
    #
    # TODO (cies): re-raise any connection errors with more intuitive names
    def get_from_wp_api(route)
      response = Faraday.get "#{ Rails.configuration.x.wordpress_url }?json_route=/#{ route }"
      JSON.parse(response.body)
    end

    #
    # List of invalid api responses
    #
    # TODO (cies): refactor to WpCache::WP_API_ERROR_CODES
    def invalid_api_responses
      %w( json_no_route json_post_invalid_type )
    end
  end
end
