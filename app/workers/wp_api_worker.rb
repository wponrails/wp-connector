require 'sidekiq'

#
# This worker is used to schedule a `create_or_update` class method call
# on the provided model for ASAP.
# The implementation of `create_or_update` is up to the model.
#
class WpApiWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(klass, wp_id)
    klass.constantize.create_or_update(klass.constantize.wp_type, wp_id)
  end
end
