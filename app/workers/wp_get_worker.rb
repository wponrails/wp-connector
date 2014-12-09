class WpGetWorker
  include Sidekiq::Worker

  def perform(id, objects)
    objects.classify.constantize.on_save(id, objects)
  end
end
