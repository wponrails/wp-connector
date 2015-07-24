require "sidekiq"

#
# This worker is used to schedule a `create_or_update` class method call
# on the provided model for ASAP.
# The implementation of `create_or_update` is up to the model.
#
class WpApiWorker
  include Sidekiq::Worker

  def perform(klass, wp_id, preview = false)
    cklass = klass.constantize
    cklass.create_or_update(cklass.wp_type, wp_id, preview)
  rescue Exceptions::WpApiResponseError => e
    Rails.logger.warn("[FAILED JOB] #{e.message}")
  end
end
