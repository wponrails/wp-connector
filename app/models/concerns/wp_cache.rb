require 'faraday'

<<<<<<< HEAD
# WpCache
=======
#
# By mixing this concern into an ActiveRecord model it gains functionality
# needed for caching WP content.
#
>>>>>>> fbe694cbc9648f89fa2e9c9353c2787aa03150dc
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

<<<<<<< HEAD
    def purge(wp_id)
      begin
        find(wp_id).first!.destroy
      rescue
        logger.warn "Could not find #{ self } with id #{ wp_id }."
      end
=======
    #
    # Schedules a `create_or_update` call to itself.
    #
    def schedule_create_or_update(wp_type, wp_id)
      WpApiWorker.perform_async(self, wp_type, wp_id)
>>>>>>> fbe694cbc9648f89fa2e9c9353c2787aa03150dc
    end

    #
    # Gets the content from the WP API, finds-or-creates a record for it,
    # and passes it the content by the `update_wp_cache` instance method.
    #
    def create_or_update(wp_type, wp_id)
      return unless wp_id.is_a? Fixnum or wp_id.is_a? String
<<<<<<< HEAD
      response = Faraday.get "#{ Rails.configuration.x.wordpress_url }?json_route=/#{ wp_type }/#{ wp_id }"
      wp_json = JSON.parse(response.body)
      #WP API will return a 'json_no_route' code if the route is incorrect or the specified entry is none existant
      #If so, do not 'first_or_create'
      return if wp_json["code"] == "json_no_route"
      where(id: wp_id).first_or_create.update_wp_cache(wp_json)
    end

    def create_or_update_all(wpclass)
      response = Faraday.get "#{ Rails.configuration.x.wordpress_url }?json_route=/#{ wpclass.pluralize.downcase }"
=======
      response = Faraday.get "#{Settings.wordpress_url}?json_route=/#{wp_type}/#{wp_id}"
      wp_json = JSON.parse(response.body)

      # WP API will return a 'json_no_route' code if the route is incorrect or
      # the specified entry is none existant. If so return early.
      return if wp_json["code"] == "json_no_route"

      # FIXME (cies): Post type will go
      joins(:post).where(posts: {post_id: wp_id}).first_or_create.update_wp_cache(wp_json)
    end

    #
    # Gets all WP IDs for a class of WP content form the WP API,
    # finds-or-creates a record for it, and passes it the content by
    # the `update_wp_cache` instance method.
    # Removes records with unknown IDs.
    #
    def create_or_update_all(wp_class)
      response = Faraday.get "#{Settings.wordpress_url}?json_route=/#{wp_class.pluralize.downcase}"
>>>>>>> fbe694cbc9648f89fa2e9c9353c2787aa03150dc
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
      # FIXME (cies): Post type will go
      joins(:post).where('posts.post_id = ?', wp_id).first!.destroy
    rescue
      logger.warn "Could not purge #{self} with id #{wp_id}, no record with that id was found."
    end
  end
end
