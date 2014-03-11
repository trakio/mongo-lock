require 'coveralls'
Coveralls.wear!
require 'mongo-lock'
require 'mongo'
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

  require 'pry'

  include MongoHelper

  config.before :each do
    database.drop_collection("locks")
    database.drop_collection("other_locks")
    database.drop_collection("another_locks")
    Mongo::Lock.configure collection: my_collection
  end

  config.after :each do
  end

  config.after :suite do
    # connection.drop_database("mongo_lock_tests")
  end

end
