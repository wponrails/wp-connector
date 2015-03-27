require 'wp-connector/version'
require 'wp-connector/railtie' if defined?(Rails)
require 'exceptions'

module WpConnector
  class Engine < ::Rails::Engine; end
end
