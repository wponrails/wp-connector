require 'sidekiq'

#
# This worker is used to schedule a `create_or_update` class method call
# on the provided model for ASAP.
# The implementation of `create_or_update` is up to the model.
#
class WpApiWorker
  include Sidekiq::Worker

  def perform(klass, wp_id = nil, preview = false)
    cklass = klass.constantize
    if wp_id
      cklass.create_or_update(cklass.wp_type, wp_id, preview)
    else
      cklass.update_options()
    end
  rescue Exceptions::WpApiResponseError => e
    Rails.logger.warn ("[FAILED JOB] " + e.message)
  end
end
