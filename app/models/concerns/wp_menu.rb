module WpMenu
  extend ActiveSupport::Concern

  MAPPABLE_ATTRS = %w( name slug description count items )

  included do
    serialize :items
  end

  def update_menu(json)
    WpMenu::MAPPABLE_ATTRS.each { |wp_attr| send("#{wp_attr}=", json[wp_attr]) }
    save!
  end

  module ClassMethods
    def wp_type
      'menus'
    end
  end
end
