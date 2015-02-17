#
# This concern may be mixed into a controller to add webhook "end point"
# functionality to it.
#
module WpWebhookEndpoint
  extend ActiveSupport::Concern

  #
  # Convenience method for finding the `wp_id` of an incoming POST request.
  #
  def wp_id_from_params
    # The `parent_ID` has precedence over `ID` as the former contains
    # the actual ID used by WP in case multiple versions exist.
    params[:parent_ID] || params[:ID]
  end
end
