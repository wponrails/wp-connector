module WpConnection
  extend ActiveSupport::Concern

  included do 
    after_filter :render_nothing
  end

  def render_nothing
    render nothing: true
  end

  def sync_cache(model_name, wp_type)
    # The `parent_ID` has precedence over `ID` as the former contains
    # the actual ID used by WP in case multiple versions exist.
    wp_id = params[:parent_ID] || params[:ID]
    WpGetWorker.perform_async(model_name, wp_type, wp_id)
  end
end
