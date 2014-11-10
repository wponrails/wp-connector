class WpConnectorController < ApplicationController
  def posts
  end

  def post_save
    render nothing: true

    wp_id = params[:ID] unless wp_id = params[:parent_ID]

    WpGetWorker.perform_async(wp_id)
  end
end
