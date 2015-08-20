module WpPost
  extend ActiveSupport::Concern

  included do
    serialize :acf_fields
  end

  # TODO (cies): rename to update_wp_post_attributes
  def update_post(json)
    self.class.mappable_wordpress_attributes.each do |wp_attribute|
      send("#{wp_attribute}=", json[wp_attribute])
    end

    language = json['terms']['language'][0]['slug']
    self.send("wp_id_#{language}=", json['ID'])
    self.polylang_id  = json['terms']['post_translations'][0]['ID'] if json['terms']['post_translations'].present?
    # Use gmt date to ignore timezone settings in WordPress
    self.published_at = json['date_gmt']
    self.order        = json['menu_order']
  end

  def update_post!(json)
    update_post(json)
    save!
  end

  module ClassMethods
    # TODO (cies): refactor to constant WpPost::MAPPABLE_ATTRS
    def mappable_wordpress_attributes
      %w( slug title status content excerpt acf_fields )
    end

    def wp_type
      self.to_s.demodulize.underscore.pluralize
    end
  end
end
