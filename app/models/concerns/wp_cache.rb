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

<<<<<<< HEAD
    def purge_cache(wp_id)
      m = self.find(wp_id)
      if m
        m.destroy
      else
=======
    def purge(wp_id)
      begin
        self.joins(:post).where('posts.post_id = ?', wp_id).first!.destroy
      rescue
>>>>>>> d4a0798f134bcfd7e27b3bd9926e8f6449495f15
        logger.warn "Could not find #{self} with id #{wp_id}."
      end
    end

<<<<<<< HEAD
    def retrieve_and_update_wp_cache(wp_type, wp_id)
      response = Faraday.get "#{Rails.configuration.x.wordpress_url}/#{wp_type}/#{wp_id}"
=======
    def create_or_update(wp_type, wp_id)
      return unless wp_id.is_a? Fixnum or wp_id.is_a? String

      response = Faraday.get "#{Settings.wordpress_url}?json_route=/#{wp_type}/#{wp_id}"
>>>>>>> d4a0798f134bcfd7e27b3bd9926e8f6449495f15
      wp_json = JSON.parse(response.body)

      #WP API will return a 'json_no_route' code if the route is incorrect or the specified entry is none existant
      #If so, do not 'first_or_create'
      return if wp_json["code"] == "json_no_route"

      self.joins(:post).where(posts: {post_id: wp_id}).first_or_create.update_wp_cache(wp_json)
    end

<<<<<<< HEAD
    def get_and_save_all(wpclass)
      response = Faraday.get "#{Rails.configuration.x.wordpress_url}/#{wpclass.pluralize.downcase}"
=======
    def create_or_update_all(wpclass)
      response = Faraday.get "#{Settings.wordpress_url}?json_route=/#{wpclass.pluralize.downcase}"
>>>>>>> d4a0798f134bcfd7e27b3bd9926e8f6449495f15
      wp_json = JSON.parse(response.body)
      ids = []
      wp_json.each do |json|
        self.where(wp_id: json['ID']).first_or_create.update_wp_cache(json)
        ids << json['ID']
      end

<<<<<<< HEAD
      if !ids.empty?
        deleted_ids = self.where.not(id: ids)
        if !deleted_ids.empty?
          deleted_ids.each do |deleted_id|
            self.destroy(deleted_id)
          end
        end
      end

=======
      self.where('wp_id NOT IN (?)', ids).destroy_all unless ids.empty?
>>>>>>> d4a0798f134bcfd7e27b3bd9926e8f6449495f15
    end
  end
end
