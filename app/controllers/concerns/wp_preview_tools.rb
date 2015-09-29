#
# This concern may be mixed into a controller to add common functinality
# for preview rendering, and preview token validation.
#
module WpPreviewTools
  extend ActiveSupport::Concern

  THRESHOLD = 5

  #
  # Validates preview tokens for wp_post_models that are not published.
  # for instance the statuses `draft` and `pending`.
  #
  def validate_preview_token(wp_post_model, &block)
    return if wp_post_model.status == "publish"

    unless params[:token] == token(wp_post_model)
      head :unauthorized and return unless block_given?

      block.call
    end

    # return true for clearer debugging
    return true
  end

  #
  # Creates a token to verify previews requests
  #
  def token(wp_post_model)
    hash_inputs = Rails.configuration.x.wp_connector_secret + wp_post_model.slug
    Digest::SHA2.new(256).hexdigest hash_inputs
  end

  #
  # Retries loading of a WpCache model, if it was not found the first time.
  # This to avoid NotFound errors due to the delaying of WP API calls.
  #
  def retry_when_preview(retrying = false, threshold = 0, &block)
    raise "retry_when_preview requires a block" unless block_given?
    return block.call
  rescue ActiveRecord::ActiveRecordError => e
    raise e unless params[:preview] || retrying
    return nil if THRESHOLD < threshold

    sleep 1.5

    return retry_when_preview(true, threshold + 1, &block)
  end
end
