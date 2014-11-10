# wp-connector

This gem is part of project called WordPress Editor Platform (WPEP), that advocates using WP as a means to create and edit content while using something else (in this case a Rails application) to serve the content.  WPEP makes use of:

* [**HookPress**](), a configurable WP plugin that allows WP actions to trigger webhook calls.
* [**wp-rest-api**](), a WP plugin that adds a modern RESTful web-API to a WordPress site. This module is scheduled to be shipped as part of WordPress 4.1.

With WPEP the content's master data resides in WP, as that's where is it created and modified.  The Rails application that is connected to WP stores merely a copy of the data, a cache, on the basis of which the public requests are served.

The main reasons for not using WP to serve public web requests:

* **Security** -- The internet is a dagerous place and WordPress has proven to be a popular target for malicious hackers.
* **Performance** -- Performance tuning WP is difficult, especially when a generic caching-proxy (such as Varnish) is not viable due to dynamic content, application frameworks (such as Rails) allow the kind of fine grained caching strategies that are needed to serve high-traffic websites.
* **Reduce the TCO of customizations** -- Customizing WP, and maintaining those customizations, is laborious and error prone compared to building custom functionality on top of an application framework (which is specifically designed for that purpose).



## How it works

After the Rails application receives the webhook call, thereby notifying the Rails app that some content is created or modified, a delayed job is scheduled with Sidekiq to fetch the content a fraction of a second later.  The new-or-modified content is fetched in a delayed job in order to respond to WP's webhook call immediately (WP blocks on webhook calls, which may make the admin backend UI feel sluggish), besides this it also allows WP to first complete all the actions that may be triggered.

The delayed job fetches the relevant content from WP using WP's REST-API (this can be one or more requests), then possibly transforms and/or enriches the data, and finally stores it using a normal ActiveRecord model. The logic for the fetch and transform/enrich steps is simply part of the ActiveRecord model definition.



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wpep', :github => 'hoppinger/wp-connector'
```

And then execute:

    bundle



## Usage

In WordPress install the following plugins: HookPress and wp-api.

When using the wonderful ACF plugin, consider installing the `wp-api-acf` from this repository (find it in `wordpress/plugin`).

In WordPress configure webhooks (HookPress) from the admin backend. Make sure that it triggers webhook calls for all changes in the content that is to be served from the Rails app.  The Webhook action needs to have send at least the `ID` and `Parent_ID` fields, other fields generally not needed.  Point the target URL of the Webhooks to the `post_save` in the Rails app.



## Todo

* Extend it from Post type into other types (or make it generic).
* Publish it to Rubygems.



## Contributing

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Submit a "Pull Request".
