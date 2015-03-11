module WpSEO
  extend ActiveSupport::Concern

  included do
    serialize :seo_fields
  end

  def update_wp_seo_attributes(json)
    self.seo_fields = json['seo_fields']
    save!
  end
end
