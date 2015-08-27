require 'faraday'
require 'php_serialize'

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
    def schedule_create_or_update(wp_id, preview = false, request = nil)
      extra_info = request ? " after #{request.fullpath} -- #{request.body.read}" : ""
      Rails.logger.info("SCHEDULED by #{self.name}" + extra_info)
      WpApiWorker.perform_async(self, wp_id, preview)
    end

    def update_options
      wp_json = get_from_wp_api "options"
      # WP API will return a code if the route is incorrect or
      # the specified entry is none existant. If so return early.
      return if wp_json[0] and invalid_api_responses.include? wp_json[0]["code"]
      Option::update_wp_cache(wp_json)
    end

    #
    # Gets the content from the WP API, finds-or-creates a record for it,
    # and passes it the content by the `update_wp_cache` instance method.
    #
    def create_or_update(wp_type, wp_id, preview = false)
      return unless wp_id.is_a? Fixnum or wp_id.is_a? String
      maybe_preview_segment = (preview ? "preview/" : "")
      wp_json = get_from_wp_api "#{ wp_type }/#{ maybe_preview_segment }#{ wp_id }"
      # WP API will return a code if the route is incorrect or
      # the specified entry is none existant. If so return early.
      return if wp_json[0] and invalid_api_responses.include? wp_json[0]["code"]
      get_model(wp_json)
    end

    def get_model(wp_json)
      if wp_json['terms']['post_translations'].present?
        model = where(polylang_id: wp_json['terms']['post_translations'][0]['ID']).first
        return model.update_wp_cache(wp_json) unless model.nil?

        translations = PHP.unserialize(wp_json['terms']['post_translations'][0]['description'])

        translations.each do |locale, id|
          model = includes(:translations)
            .where("#{self.name.downcase}_translations.wp_id = ?", id.to_s)
            .references(:translations).first

          return model.update_wp_cache(wp_json) unless model.nil?
        end
      else
        translation = self::Translation.where('wp_id = ?', wp_json['ID'].to_s).first

        if translation.nil?
          model = self.new
          model.update_wp_cache(wp_json)
        else
          model = self.where('id = ?', translation.send("#{self.name.downcase}_id")).first
          model.update_wp_cache(wp_json)
        end

        # joins(:translations)
        #   .where("#{self.name.downcase}_translations.wp_id = ?", wp_json['ID'].to_s)
        #   .references(:translations)
        #   .first_or_initialize.update_wp_cache(wp_json)
        # where("wp_id_#{wp_json['terms']['language'][0]['slug']} = ?", wp_json['ID']).first_or_initialize.update_wp_cache(wp_json)
      end
    end

    def create_or_update_all
      if paginated_models.include?(wp_type)
        create_or_update_all_paginated
      else
        create_or_update_all_non_paginated
      end
    end

    #
    # Gets all WP IDs for a class of WP content form the WP API,
    # finds-or-creates a record for it, and passes it the content by
    # the `update_wp_cache` instance method.
    # Removes records with unknown IDs.
    #
    # TODO (dunyakirkali) clean up
    def create_or_update_all_paginated
      page = 0
      ids = []
      max_page = (ENV['MAX_PAGE'].to_i == 0 ? 999 : ENV['MAX_PAGE'].to_i)
      while page < max_page do
        Rails.logger.info " page #{page}"
        wp_json = get_from_wp_api(wp_type, page)
        break if wp_json.empty?
        ids << wp_json.map do |json|
          wp_id = json['ID']
          where(wp_id: wp_id).first_or_initialize.update_wp_cache(json)
          wp_id
        end
        page = page + 1
      end
      where('wp_id NOT IN (?)', ids.flatten).destroy_all unless ids.empty?
    end

    # TODO (dunyakirkali) doc
    def create_or_update_all_non_paginated
      wp_json = get_from_wp_api(wp_type)
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
      model = includes(:translations)
        .where("#{self.name.downcase}_translations.wp_id = ?", wp_id.to_s)
        .references(:translations).first

      # remove translation with wp_id
      self::Translation.where('wp_id = ?', wp_id.to_s).first!.destroy

      # remove model if no more translations
      if model.translations.count == 0
        model.destroy!
      end
    rescue
      logger.warn "Could not purge #{self} with id #{wp_id}, no record with that id was found."
    end

    private

    #
    # Convenience method for calling the WP API.
    #
    # TODO (cies): re-raise any connection errors with more intuitive names
    def get_from_wp_api(route, page = -1)
      # TODO (dunyakirkali) pass filter through args to get_from_wp_api
      posts_per_page = (ENV['PER_PAGE'].to_i == -1 ? -1 : ENV['PER_PAGE'].to_i)
      base = WpConnector.configuration.wordpress_url
      unless paginated_models.include?(wp_type)
        url = "#{base}?json_route=/#{route}&filter[posts_per_page]=-1"
      else
        url = "#{base}?json_route=/#{route}&filter[posts_per_page]=#{posts_per_page}&page=#{page}"
      end
      Rails.logger.info url
      response = Faraday.get url
      # If the response status is not 2xx or 5xx then raise an exception since then no retries needed.
      unless response.success? || (response.status >= 500 && response.status <= 599)
        fail Exceptions::WpApiResponseError, "WP-API #{url} responded #{response.status} #{response.body}"
      end
      JSON.parse(response.body)
    end

    #
    # List of paginated models
    #
    def paginated_models
      models = WpConnector.configuration.wp_api_paginated_models
      if models.empty?
        Rails.logger.warn "Please specifiy WpConnector.configuration.wp_api_paginated_models, as the default is DEPRICATED"
        models = %w( articles news_articles pages media)
      end
      models
    end

    #
    # List of invalid api responses
    #
    # TODO (cies): refactor to WpCache::WP_API_ERROR_CODES
    def invalid_api_responses
      %w( json_no_route json_post_invalid_type json_user_cannot_read )
    end
  end
end
