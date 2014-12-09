module WpConnection
  extend ActiveSupport::Concern

  included do 
    after_filter :render_nothing
  end

  def render_nothing
    render nothing: true
  end

  def save_async(object)
    wp_id = params[:ID] unless wp_id = params[:parent_ID]

    WpGetWorker.perform_async(wp_id, object)
  end
end
