#
# This concern may be mixed into a controller to add webhook "end point"
# functionality to it.
#
module WpWebhookEndpoint
  extend ActiveSupport::Concern

  def self.included(base)
    base.before_action :require_valid_api_key
  end

  private

  #
  # Convenience method for finding the `wp_id` of an incoming POST request.
  #
  def wp_id_from_params
    # The `parent_ID` has precedence over `ID` as the former contains
    # the actual ID used by WP in case multiple versions exist.
    params[:parent_ID] || params[:ID] || params[:id]
  end

  #
  # Convenience method for finding the `preview` of an incoming POST request.
  #
  def preview_from_params
    # some systems send in a string '1' or '0' for booleans. Map it to boolean:
    to_bool params[:preview]
  end

  #
  # Convenience method for rendering the most common JSON responses.
  #
  def render_json_200_or_404(success)
    if success
      render json: {status: 200, message: 'OK'}
    else
      render json: {status: 404, message: 'Not found'}
    end
  end

  def require_valid_api_key
    head :unauthorized unless params[:api_key] == Rails.configuration.x.wp_connector_api_key
  end

  #
  # helper method to check if a posted string param is a boolean
  #
  def to_bool(string)
    return true if string == true || string =~ (/^(true|t|yes|y|1)$/i)
    return false if string == false || string.blank? || string =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end
end
