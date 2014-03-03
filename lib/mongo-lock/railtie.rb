# encoding: utf-8
require "mongoid"
require "mongoid/config"
require "mongoid/railties/document"
require "rails"
require "rails/mongoid"

module Rails
  module Mongo
    module Lock
      class Railtie < Rails::Railtie

        rake_tasks do
          load "mongoid/railties/mongo.rake"
        end

      end
    end
  end
end
