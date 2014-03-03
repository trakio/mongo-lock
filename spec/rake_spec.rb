require 'spec_helper'
require 'rake'
# load File.expand_path("../lib/railties/mongo.rake", __FILE__)
load 'mongo-lock/railties/mongo.rake'
task :environment do ; end

describe 'mongolock' do

  describe 'mongolock:clear_expired' do

    it "calls .clear_expired" do
      expect(Mongo::Lock).to receive(:clear_expired)
      Rake::Task['mongolock:clear_expired'].invoke
    end

  end

  describe 'mongolock:release_all' do

    it "calls .release_all" do
      expect(Mongo::Lock).to receive(:release_all)
      Rake::Task['mongolock:release_all'].invoke
    end

  end

end
