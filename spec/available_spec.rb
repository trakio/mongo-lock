require 'spec_helper'

describe Mongo::Lock do

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
