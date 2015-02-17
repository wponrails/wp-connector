wp-connector
============

This gem is part of project called WordPress Editor Platform (WPEP), that advocates using WP as a means to create and edit content while using something else (in this case a Rails application) to serve public request and provide a basis for customizations.  WPEP makes use of the following WP plugins:

* [**HookPress**](https://wordpress.org/plugins/hookpress) ([site](http://mitcho.com/code/hookpress), [repo](https://github.com/mitcho/hookpress)) — WP plugin by which WP actions can be configured to trigger HTTP request to abritrary URLs (webhooks).
* [**json-rest-api**](https://wordpress.org/plugins/json-rest-api) ([site](http://wp-api.org), [repo](https://github.com/WP-API/WP-API)) — WP plugin that adds a modern RESTful web-API to a WordPress site. This module is scheduled to be shipped as part of WordPress 4.1.

With WPEP the content's master data resides in WP, as that's where is it created and modified.  The Rails application that is connected to WP stores merely a copy of the data, a cache, on the basis of which the public requests are served.

The main reasons for not using WP to serve public web requests:

* **Security** — The internet is a dangerous place and WordPress has proven to be a popular target for malicious hackers. By not serving public request from WP, but only the admin interface, the attack surface is significantly reduced.
* **Performance** — Performance tuning WP can be difficult, especially when a generic caching-proxy (such as Varnish) is not viable due to dynamic content such as ads or personalization.  Application frameworks provide means for fine-grained caching strategies that are needed to serve high-traffic websites that contain dynamic content.
* **Cost (TCO) of customizations** — Customizing WP, and maintaining those customizations, is laborious and error prone compared to building custom functionality on top of an application framework (which is specifically designed for that purpose).
* **Upgrade path** — Keeping a customized WP installation up-to-date can be a pain, and WP-updates come ever more often. When WP is not used to serve public requests and customizations are not built into WP most of this pain avoided.



## How it works

After the Rails application receives the webhook call from WP, simply notifying that some content is created or modified, a delayed job to fetch the content is scheduled using [Sidekiq](http://sidekiq.org).  The content is not fetch immediately, but a fraction of a second later, for two reason: (1) the webhook call is synchronous, responding as soon as possible is needed to keep the admin interface of WP responsive, and (2) it is not guaranteed that all processing has is complete by the time the webhook call is made.

The delayed job fetches the relevant content from WP using WP's REST-API (this can be one or more requests), then possibly transforms and/or enriches the data, and finally stores it using a regular ActiveRecord model. The logic for the fetch and transform/enrich steps is simply part of the ActiveRecord model definition.



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wp-connector', :github => 'hoppinger/wp-connector'
```

Then execute `bundle install`.



## Usage

In WordPress install both the HookPress and json-rest-api plugin.

When using the wonderful ACF plugin, consider installing the `wp-api-acf` plugin that can be found in this repository (find it in `wordpress/plugin`).

In WordPress configure the "Webhooks" (provided by HookPress) from the admin backend. Make sure that it triggers webhook calls for all changes in the content that is to be served from the Rails app.  The Webhook action needs to send at least the `ID` and `Parent_ID` fields, other fields generally not needed.  Point the target URLs of the Webhooks to the `post_save` route in the Rails app.

Add the wordpress json route to your rails configuration by adding the `wordpress_url` config option to your environment file in `config/environments` (e.g.
 `config/environments/development.rb`):
```ruby
config.x.wordpress_url: "http://wpep.dev/?json_route="
```
Here `wpep.dev` is the domain for your Wordpress site.


Installing a route for the webhook endpoint (in `config/routes.rb` of your Rails app):

```ruby
post 'wp-connector/post_save'
post 'wp-connector/post_delete'
```

Create a `WpConnectorController` class (in `app/controllers/wp_connector_controller.rb`) that specifies a `webhook` action. For example for the `Post` type:

```ruby
class WpConnectorController < ApplicationController
  include WpConnection

  def post_save
     Post.schedule_create_or_update('posts', wp_id_from_params)
  end

  def post_delete
    Post.purge(wp_id_from_params)
  end
end
```

Create a model for each of the content types that you want to cache by the Rails application. This is an example for the `Post` model:

```ruby
class Post < ActiveRecord::Base
  include WpCache

  def update_wp_cache(json)
    # First create or update the author
    author_params = json["author"]
    author = Author.find_or_create(author_params["ID"])
    author.update_wp_cache(author_params)

    self.id         = json["ID"]
    self.title      = json["title"]
    self.content    = json["content"]
    self.slug       = json["slug"]
    self.excerpt    = json["excerpt"]
    self.updated_at = json["updated"]
    self.created_at = json["date"]
    self.author     = author
    self.save
  end
end
```

And the examplefor the `Author` model:

```ruby
class Author < ActiveRecord::Base
  include WpCache

  def update_wp_cache(json)
    self.id           = json["ID"]
    self.username     = json["username"]
    self.name         = json["name"]
    self.first_name   = json["first_name"]
    self.last_name    = json["last_name"]
    self.nickname     = json["nickname"]
    self.slug         = json["slug"]
    self.url          = json["URL"]
    self.description  = json["description"]
    self.registered   = json["registered"]
    self.save
  end
end
```


And create the migration for this model:

```ruby
class CreatePostsAndAuthors < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string  :title
      t.integer :author_id
      t.text    :content
      t.string  :slug
      t.text    :excerpt
      t.timestamps
    end

    create_table :authors do |t|
      t.string :username
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :nickname
      t.string :slug
      t.string :url
      t.string :description
      t.string :registered
      t.timestamps
    end
  end
end
```



## Todo

* Publish it to Rubygems.



## Contributing

You know the drill :)

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Submit a "Pull Request".



## License

Copyright (c) 2014-2015, Hoppinger B.V.

All files in this repository are MIT-licensed, as specified in the [LICENSE file](https://github.com/hoppinger/wp-connector/blob/features/master/LICENSE).
