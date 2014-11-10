# Wpep

With this gem you can use a Wordpress application as your CMS, which can be served by your rails application. Edits in the CMS are sent to the rails application and stored in Activerecord. You can build your website in rails allowing a much better performing website. 

## Installation

Add this line to your application's Gemfile:

    gem 'wpep', :github => 'hoppinger/wpep'

And then execute:

    $ bundle


## Usage

In WordPress install the following plugins:
hookpress, wp-api 

If you are using ACF also install the acf plugin and the wp-api-acf plugin (which can be found here in vendor/wordpress/plugin)

In WordPress configure Webhooks (hookpress) for changes in the content you want to publish in your rails app. The Webhook action needs to have fields ID and Parent_ID. Other fields are not needed, the actual content is pulled using the wp-api plugin. Point the URL of the webhook to post_save in your rails app. Currently this gem only handles changes in posts, more will follow.

## Contributing

1. Fork it ( https://github.com/hoppinger/wpep/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
