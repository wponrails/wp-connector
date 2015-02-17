require 'sidekiq'

class WpGetWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(model_name, wp_type, wp_id)
    model_name.constantize.create_or_update(wp_type, wp_id)
  end
end
