require 'spec_helper'

describe Mongo::Lock do

  describe '.configure' do

    it "Creates a new configuration" do
      first_configuration = Mongo::Lock.configuration
      Mongo::Lock.configure
      expect(Mongo::Lock.configuration).to_not be first_configuration
    end

    it "passes on options hash" do
      Mongo::Lock.configure limit: 3
      Mongo::Lock.configure frequency: 4
      expect(Mongo::Lock.configuration.limit).to be 3
      expect(Mongo::Lock.configuration.frequency).to be 4
    end

    it "passes on block" do
      Mongo::Lock.configure frequency: 4
      Mongo::Lock.configure do |config|
        config.limit = 5
      end
      expect(Mongo::Lock.configuration.limit).to be 5
      expect(Mongo::Lock.configuration.frequency).to be 4
    end

  end

  describe '#configure' do

    let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence' }

    it "Creates a new configuration" do
      first_configuration = lock.configuration
      lock.configure
      expect(lock.configuration).to_not be first_configuration
    end

    it "passes on options hash" do
      lock.configure limit: 3
      expect(lock.configuration.limit).to be 3
    end

    it "passes on block" do
      lock.configure do |config|
        config.limit = 5
      end
      expect(lock.configuration.limit).to be 5
    end

  end

end