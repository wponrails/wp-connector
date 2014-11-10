class Post < ActiveRecord::Base
  include WpCache

  def self.on_post_save(wp_id)
    wp_json = get_from_wp('posts', wp_id)
    if p = Post.where('id= ?', wp_id).first
      p.from_wp_json(wp_json)
    else
      p = Post.new
      p.from_wp_json(wp_json)
    end
    p.save!
  end

  def from_wp_json(json)
    self.id = json["ID"]
    self.title = json["title"]
    self.content = json["content"]
    self.slug = json["slug"]
    self.excerpt = json["excerpt"]
    self.updated_at =  json["updated"]
    self.created_at =  json["date"]

    # TODO add author and other related objects
  end
end
