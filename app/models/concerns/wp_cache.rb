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
    def schedule_create_or_update(wp_type, wp_id)
      WpGetWorker.perform_async(self, wp_type, wp_id)
    end

    def purge(wp_id)
      begin
        joins(:post).where('posts.post_id = ?', wp_id).first!.destroy
      rescue
        logger.warn "Could not find #{self} with id #{wp_id}."
      end
    end

    def create_or_update(wp_type, wp_id)
      return unless wp_id.is_a? Fixnum or wp_id.is_a? String

      response = Faraday.get "#{Settings.wordpress_url}?json_route=/#{wp_type}/#{wp_id}"
      wp_json = JSON.parse(response.body)

      #WP API will return a 'json_no_route' code if the route is incorrect or the specified entry is none existant
      #If so, do not 'first_or_create'
      return if wp_json["code"] == "json_no_route"

      joins(:post).where(posts: {post_id: wp_id}).first_or_create.update_wp_cache(wp_json)
    end

    def create_or_update_all(wpclass)
      response = Faraday.get "#{Settings.wordpress_url}?json_route=/#{wpclass.pluralize.downcase}"
      wp_json = JSON.parse(response.body)
      ids = []
      wp_json.each do |json|
        where(wp_id: json['ID']).first_or_create.update_wp_cache(json)
        ids << json['ID']
      end

      where('wp_id NOT IN (?)', ids).destroy_all unless ids.empty?
    end
  end
end
