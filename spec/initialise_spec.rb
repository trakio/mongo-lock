require 'spec_helper'

describe Mongo::Lock do

  describe '#initialise' do

    let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01 }

    it "creates a new configuration object" do
      expect(lock.configuration).to be_a Mongo::Lock::Configuration
    end

    it "passes it the class configuration" do
      Mongo::Lock.configure limit: 3
      expect(lock.configuration.limit).to be 3
    end

    it "allows override of the class configuration" do
      Mongo::Lock.configure limit: 3
      lock = Mongo::Lock.new 'my_lock', limit: 4
      expect(lock.configuration.limit).to be 4

    end

    context "when the key is already acquired by this owner" do

      it "acquires that lock" do
        collection.insert key: 'my_lock', owner: 'spence', expires_at: 1.minute.from_now
        expect(lock.acquired?).to be_true
      end

    end

  end

end
