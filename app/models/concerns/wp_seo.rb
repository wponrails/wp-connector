module WpSEO
  extend ActiveSupport::Concern

  included do
    serialize :seo_fields
  end

  def update_wp_seo_attributes(json)
    return unless json.is_a?(Hash)
    self.seo_fields = json["seo_fields"]
    save!
  end
end
