module WpPost
  extend ActiveSupport::Concern

  included do
    serialize :acf_fields
  end

  def update_post(json)
    mappable_wordpress_attributes.each do |wp_attribute|
      send(wp_attribute, json[wp_attribute])
    end

    self.wp_id        = json['ID']
    self.author_id    = json['author']
    self.published_at = json['date']
    self.order        = json['menu_order']
    save!
  end

  class << self
    def mappable_wordpress_attributes
      %w( slug title status content excerpt acf_fields )
    end
  end
end
