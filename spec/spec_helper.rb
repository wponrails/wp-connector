require 'bundler/setup'
Bundler.setup

# require 'wp-connector'
require 'rspec/its'

Dir["./spec/support/**/*.rb"].sort.each { |f| require f}

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.order = 'random'
end