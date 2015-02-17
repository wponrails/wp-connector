module WpWebhookEndpoint
  extend ActiveSupport::Concern

  def wp_id_from_params
    # The `parent_ID` has precedence over `ID` as the former contains
    # the actual ID used by WP in case multiple versions exist.
    params[:parent_ID] || params[:ID]
  end
end
