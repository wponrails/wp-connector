require 'sidekiq'

#
# This worker is used to schedule a `create_or_update` class method call
# on the provided model for ASAP.
# The implementation of `create_or_update` is up to the model.
#
class WpApiWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(klass, wp_id, preview = false)
    cklass = klass.constantize
    cklass.create_or_update(cklass.wp_type, wp_id, preview)
  end
end
