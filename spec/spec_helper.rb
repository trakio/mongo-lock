require 'coveralls'
Coveralls.wear!
require 'rails'
require 'mongo-lock'
require 'mongo'
require 'moped'
require 'active_support/core_ext/numeric/time'

RSpec.configure do |config|

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.order = :random
  config.color = true
  config.formatter = "Fuubar"
  config.filter_run_excluding :wip => true

  Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f }
  Dir[File.expand_path("../examples/**/*.rb", __FILE__)].each {|f| require f }

  require 'pry'

  include MongoHelper

  config.after :each do
  end

  config.after :suite do
    # connection.drop_database("mongo_lock_tests")
  end

end
