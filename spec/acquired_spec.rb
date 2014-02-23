require 'spec_helper'

describe Mongo::Lock do

  describe '#acquired?' do

    let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01 }

    context "when the lock has been acquired" do

      it "returns true" do
        lock.acquire
        expect(lock.acquired?).to be_true
      end

    end

    context "when the lock hasn't been acquired" do

      it "returns false" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.minute.from_now
        lock.acquire
        expect(lock.acquired?).to be_false
      end

    end

    context "when the lock is already acquired but by the same owner in a different thread" do

      it "returns true" do
        collection.insert key: 'my_lock', owner: 'spence'
        lock.acquire
        expect(lock.acquired?).to be_true
      end

    end

    context "when the lock was acquired but has since expired" do

      it "returns false" do
        collection.insert key: 'my_lock', owner: 'spence', expires_at: 0.01.seconds.from_now
        lock.acquire
        sleep 0.02
        expect(lock.acquired?).to be_false
      end

    end

    context "when the lock was acquired but has since been released" do

      it "returns false" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.minute.ago
        lock.acquire
        lock.release
        expect(lock.acquired?).to be_false
      end

    end

  end

end
