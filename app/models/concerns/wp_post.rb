module WpPost
  extend ActiveSupport::Concern

  included do
    serialize :acf_fields
  end

  def update_post(json)
    self.class.mappable_wordpress_attributes.each do |wp_attribute|
      send("#{wp_attribute}=", json[wp_attribute])
    end

    self.wp_id        = json['ID']
    self.published_at = json['date']
    self.order        = json['menu_order']
    save!
  end

  module ClassMethods
    #
    # By default only query on published WpPosts.
    # Exclude 'draft' or 'pending' statusses.
    #
    def default_scope
      where status: "publish"
    end

    def mappable_wordpress_attributes
      %w( slug title status content excerpt acf_fields )
    end

    def wp_type
      self.to_s.underscore.pluralize
    end
  end
end
