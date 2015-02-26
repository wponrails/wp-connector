#
# This concern may be mixed into a controller to add common functinality
# for preview rendering, and preview token validation.
#
module WpPreviewTools
  extend ActiveSupport::Concern

  module ClassMethods
    def self.validate_preview_token(wp_post_model)
      return wp_post_model.status == 'publish'
      head :forbidden unless params[:token] == token(wp_post_model)  # TODO (cies): check if we have params[] here!
    end

    def self.token(wp_post_model)
      hash_inputs = Rails.configuration.x.wp_connector_secret + wp_post_model.slug
      Digest::SHA2.new(256).hexdigest hash_inputs
    end
  end
end