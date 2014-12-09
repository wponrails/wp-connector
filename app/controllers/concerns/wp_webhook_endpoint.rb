module WpWebhookEndpoint
  extend ActiveSupport::Concern

  included do 
    after_filter :render_nothing
  end

  def render_nothing
    render nothing: true
  end
  
  def wp_id_from_params
    # The `parent_ID` has precedence over `ID` as the former contains
    # the actual ID used by WP in case multiple versions exist.
    params[:parent_ID] || params[:ID]
  end
end
