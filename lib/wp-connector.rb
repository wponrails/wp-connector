require 'wp-connector/version'
require 'wp-connector/railtie' if defined?(Rails)

module WpConnector
  class Engine < ::Rails::Engine; end
end
