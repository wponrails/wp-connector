class WpGetWorker
  include Sidekiq::Worker

  def perform(model_name, wp_type, wp_id)
    model_name.constantize.retrieve_and_update_wp_cache(wp_type, wp_id)
  end
end
