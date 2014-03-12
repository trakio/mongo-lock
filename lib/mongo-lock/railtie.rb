# encoding: utf-8
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
