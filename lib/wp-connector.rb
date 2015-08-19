require 'wp-connector/version'
require 'wp-connector/railtie' if defined?(Rails)
require 'exceptions'

module WpConnector
  class Engine < ::Rails::Engine; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :wordpress_url, :wp_connector_api_key, :wp_api_paginated_models
  end
end
