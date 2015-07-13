module WpRedirect
  extend ActiveSupport::Concern

  def update_wp_redirect_attributes(json)
    return unless json.is_a?(Hash)

    self.wp_id = json['id']
    self.from  = json['from']
    self.to    = json['to']

    save!
  end

  # implements class methods
  module ClassMethods
    def mappable_wordpress_attributes
      %w( id from to )
    end

    def wp_type
      to_s.demodulize.underscore.pluralize
    end
  end
end
