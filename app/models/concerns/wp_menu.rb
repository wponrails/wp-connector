module WpMenu
  extend ActiveSupport::Concern

  included do
    serialize :items
  end

  def update_menu(json)
    self.class.mappable_wordpress_attributes.each do |wp_attribute|
      send("#{wp_attribute}=", json[wp_attribute])
    end

    save!
  end

  module ClassMethods
    def mappable_wordpress_attributes
      %w( name slug description count items )
    end

    def wp_type
      'menus'
    end
  end
end
