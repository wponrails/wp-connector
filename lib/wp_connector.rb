require "wp_connector/version"
require "wp_connector/railtie" if defined?(Rails)
require "exceptions"

module WpConnector
  class Engine < ::Rails::Engine; end
end
