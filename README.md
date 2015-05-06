wp-connector
============

[![Scrutinizer Code Quality](https://scrutinizer-ci.com/g/hoppinger/wp-connector/badges/quality-score.png?b=master)](https://scrutinizer-ci.com/g/hoppinger/wp-connector/?branch=master)
[![Build Status](https://scrutinizer-ci.com/g/hoppinger/wp-connector/badges/build.png?b=master)](https://scrutinizer-ci.com/g/hoppinger/wp-connector/build-status/master)
[![Code Climate](https://codeclimate.com/github/hoppinger/wp-connector/badges/gpa.svg)](https://codeclimate.com/github/hoppinger/wp-connector)
[![Test Coverage](https://codeclimate.com/github/hoppinger/wp-connector/badges/coverage.svg)](https://codeclimate.com/github/hoppinger/wp-connector)

This library is part of the [**WP on Rails**](https://github.com/wponrails) project, that limits WP to a means of managing content while using a Rails application to serve public request and provide a basis for customizations.  

To prepare a WP installation to be used in a **WP on Rails** architecture the [**wp-relinquish**](https://github.com/wponrails/wp-relinquish) plugin is provided. It provides a means to configure WP actions to send notifications as webhook calls to a Rails application equipped with **wp-connector**.

When using **WP on Rails** the content's *master data* resides in WP's database, as that's where is it created and modified.  The Rails application that is connected to WP stores merely a copy of the data, a cache, on the basis of which the public requests are served.

The main reasons for not using WP to serve public web requests:

* **Security** — The internet is a dangerous place and WordPress has proven to be a popular target for malicious hackers. By not serving public requests from WP, but only the admin interface, the attack surface is significantly reduced.
* **Performance** — Performance tuning WP can be difficult, especially when a generic caching-proxy (such as Varnish) is not viable due to dynamic content such as ads or personalization.  Application frameworks provide means for fine-grained caching strategies that are needed to serve high-traffic websites containing dynamic content.
* **Cost (TCO) of customizations** — Customizing WP, and maintaining those customizations, is costly (laborious) and risky (error prone) compared to building custom functionality on top of an application framework (which is specifically designed for that purpose).
* **Upgrade path** — Keeping a customized WP installation up-to-date can be a pain, and WP-updates come ever more often. When WP is not used to serve public requests and customizations are not built into WP most of this pain avoided.
* **Modern browser interfaces** — The new bread of JavaScript UI frameworks (such as Facebook's [React](http://facebook.github.io/react) and Google's [AngularJS](https://angularjs.org)) have features like "isomorphism" (allowing JS views to be pre-rendered on the server) and "two-way data-binding". These features expect certain server-side behavior and usually consume JSON data instead of HTML. The Rails community provides many tools to facilitate these new UI libraries from the server-side.


## How it works

After the Rails application receives the webhook call from WP, simply notifying that some content is created or modified, a delayed job to fetch the content is scheduled using [Sidekiq](http://sidekiq.org).  The content is not fetched immediately, but scheduled for a fraction of a second later, the reason for this is twofold:

1. The webhook call is synchronous, responding as soon as possible is needed to keep the admin interface of WP responsive.
2. It is not guaranteed that all WP's processing is complete (some actions may still fire) by the time the webhook call is made.

The delayed job fetches the relevant content from WP using the [WP-REST-API](http://wp-api.org) (this can be one or more requests), then possibly transforms and/or enriches the data, and finally stores it using a regular ActiveRecord model. The logic for the fetch and transform/enrich steps is simply part of the ActiveRecord model definition.


## Installation

Add this line to your Rails application's `Gemfile`:

```ruby
gem 'wp-connector', :github => 'wponrails/wp-connector'
```

Then execute `bundle install`.


## Usage

In WordPress install both the `wp-relinquish` and `json-rest-api` plugin. The wonderful ACF plugin should work out-of-the-box with `wp-relinquish`.  The `wp-relinquish` plugin needs some configuration, as specified in the README of that project.

Add the "JSON route" of the WP REST API to your Rails configuration by adding the `wordpress_url` config option to your environment files in `config/environments/` (e.g. `config/environments/development.rb`):
```ruby
Rails.configuration.x.wordpress_url = "http://wordpress-site.dev/"
```
Here `wordpress-site.dev` is the domain for your Wordpress site.

This configures some models, `['articles', 'news_articles', 'pages']`, for paginated requests to the WP-REST API.
```ruby
Rails.configuration.x.wp_api_paginated_models = %w(articles news_articles pages)
```

Also specify the wp-connector API key in the Rails configuration by adding the `wp_connector_api_key` config option to the same environment files in `config/environments/` (e.g. `config/environments/development.rb`):
```ruby
Rails.configuration.x.wp_connector_api_key="H3O5P6P1I5N8G8E4R"
```


Installing the routes for the webhook endpoint (in `config/routes.rb` of your Rails app):

```ruby
# wp-connector endpoints
post   'wp-connector/:model',     to: 'wp_connector#model_save'
delete 'wp-connector/:model/:id', to: 'wp_connector#model_delete'
```

Create a `WpConnectorController` class (in `app/controllers/wp_connector_controller.rb`) that specifies a `webhook` action. For example for the `Post` type:

```ruby
class WpConnectorController < ApplicationController
  include WpWebhookEndpoint
  skip_before_action :verify_authenticity_token

  def model_save
    model = params[:model].classify.constantize
    render_json_200_or_404 model.schedule_create_or_update(wp_id_from_params)
  end

  def model_delete
    model = params[:model].constantize
    render_json_200_or_404 model.purge(wp_id_from_params)
  end
end
```

Create a model for each of the content types that need to be cached by the Rails application.
This is an example for the `Post` model:

```ruby
class Post < ActiveRecord::Base
  include WpCache
  include WpPost

  def update_wp_cache(json)
    update_post(json)
    author = Author.find_or_create(json["author"]["ID"])
    author.update_wp_cache(json["author"])
    self.author = author
    self.save
  end
end
```

And an example of an `Author` model:

```ruby
class Author < ActiveRecord::Base
  include WpCache
  include WpPost

  def update_wp_cache(json)
    update_post(json)
    self.username     = json["username"]
    self.name         = json["name"]
    self.first_name   = json["first_name"]
    self.last_name    = json["last_name"]
    self.nickname     = json["nickname"]
    self.url          = json["URL"]
    self.description  = json["description"]
    self.registered   = json["registered"]
    self.save
  end
end
```


And create the migration for these models:

```ruby
class CreatePostsAndAuthors < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.integer :wp_id
      t.string  :title
      t.integer :author_id
      t.text    :content
      t.string  :slug
      t.text    :excerpt
      t.timestamps
    end

    create_table :authors do |t|
      t.integer :wp_id
      t.string  :username
      t.string  :name
      t.string  :first_name
      t.string  :last_name
      t.string  :nickname
      t.string  :slug
      t.string  :url
      t.string  :description
      t.string  :registered
      t.timestamps
    end
  end
end
```

wp-connector assumes the model name is the same as the wp post type name.
This means the API call for, for example, the author becomes:

`http://wordpress-site.dev/?json_route=/authors/{id}`

However, in some cases the model names do not correspond.
Therefore the wp_type of a rails model can be overridden with the `wp_type` class method.

```ruby
class Author < ActiveRecord::Base
  # ... snip ...

  def self.wp_type
    'wp_post_type_name'
  end

  # ... snap ...
end
```

Resulting in the following API call:

`http://wordpress-site.dev/?json_route=/wp_post_type_name/{id}`

### Menu items

For menu items the `json-rest-api-menu-routes` WordPress plugin is required.

The implementation for menus is rather straightforward.
An example for a basic `Menu` model:

```ruby
class Menu < ActiveRecord::Base
  include WpCache
  include WpMenu

  def update_wp_cache(json)
    update_menu(json)
  end
end
```

And the migration would be:

```ruby
class CreateMenus < ActiveRecord::Migration
  def change
    create_table :menus do |t|
      t.integer :wp_id
      t.string  :slug
      t.text    :description
      t.string  :slug
      t.integer :count
      t.text    :items
      t.timestamps
    end
  end
end
```


## Contributing

You know the drill :)

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Submit a "Pull Request".



## License

Copyright (c) 2014-2015, Hoppinger B.V.

All files in this repository are MIT-licensed, as specified in the [LICENSE file](https://github.com/wponrails/wp-connector/blob/features/master/LICENSE).
