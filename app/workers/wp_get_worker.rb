class WpGetWorker
  include Sidekiq::Worker

  def perform(id)
    Post.on_post_save(id)
  end
end