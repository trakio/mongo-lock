require 'spec_helper'

describe Mongo::Lock do

  describe '.available?' do

    it "creates and returns a new Mongo::Lock instance" do
      expect(Mongo::Lock.available? 'my_lock').to be_a Mongo::Lock
    end

    it "calls #available?" do
      expect_any_instance_of(Mongo::Lock).to receive(:available?)
      Mongo::Lock.available? 'my_lock'
    end

    context "when options are provided" do

      it "passes them to the new lock" do
        lock = Mongo::Lock.available?('my_lock', { owner: 'spence' })
        expect(lock.configuration.owner).to eql 'spence'
      end

    end

  end

  describe '#available?' do

    let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01 }

    context "when the lock is available" do

      it "returns true" do
        expect(lock.available?).to be_true
      end

    end

    context "when the lock is expired" do

      it "returns true" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.minute.ago
        expect(lock.available?).to be_true
      end

    end

    context "when the lock is already acquired but by this owner" do

      it "returns true" do
        collection.insert key: 'my_lock', owner: 'spence', expires_at: 1.minute.from_now
        expect(lock.available?).to be_true
      end

    end

    context "when the lock is already acquired" do

      it "returns false" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.minute.from_now
        expect(lock.available?).to be_false
      end

    end

  end

end
