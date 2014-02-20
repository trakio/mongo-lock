require 'mongo-lock'
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
  config.order = :random
  config.color = true
  config.formatter = "Fuubar"
  config.filter_run_excluding :wip => true
end
