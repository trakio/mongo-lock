require 'spec_helper'

describe Mongo::Lock do

  let(:lock) { Mongo::Lock.acquire('my_lock', owner: 'spence', expire_in: 0.1.seconds, timeout_in: 0.01, frequency: 0.01) }

  describe '.release' do

    it "creates a new Mongo::Lock instance" do
      lock
      expect(Mongo::Lock.release 'my_lock', owner: 'spence').to be_a Mongo::Lock
    end

    it "calls #release to release the lock" do
      expect_any_instance_of(Mongo::Lock).to receive(:release)
      Mongo::Lock.release 'my_lock', owner: 'spence'
    end

    context "when options are provided" do

      it "passes them to the new lock" do
        l = Mongo::Lock.release 'my_lock', owner: 'spence'
        # expect(l.configuration.owner).to eql 'spence'
      end

    end

  end

  describe '#release' do

    context "when lock is acquired" do

      before :each do
        collection.insert key: 'my_lock', owner: 'spence'
      end

      let(:lock) { Mongo::Lock.acquire 'my_lock', owner: 'spence' }

      it "releases the lock" do
        lock.release
        expect(collection.find(key: 'my_lock', owner: 'spence').count).to be 0
      end

      it "returns true" do
        expect(lock.release).to be_true
      end

    end

    context "when the lock isn't acquired" do

      let(:lock) { Mongo::Lock.new 'my_lock', timeout_in: 0.01, frequency: 0.01 }

      it "acquires the lock first" do
        expect(lock).to receive(:acquire).and_call_original
        lock.release
      end

      it "returns true" do
        expect(lock.release).to be_true
      end

    end

    context "when the lock isn't acquired and cant be" do

      let(:lock) { Mongo::Lock.new 'my_lock', timeout_in: 1, frequency: 0.01 }

      it "returns false" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.seconds.from_now
        expect(lock.release timeout_in: 0.01).to be_false
      end

      it "doesn't release the lock" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.seconds.from_now
        lock.release timeout_in: 0.01
        expect(collection.find(key: 'my_lock', owner: 'tobie').count).to be 1
      end

    end

    context "when the lock was acquired but has since expired" do

      it "returns true" do
        lock
        sleep 0.2
        expect(lock.release).to be_true
      end

    end

    context "when the lock was acquired but has already been released" do

      it "returns true" do
        lock.release
        expect(lock.release).to be_true
      end

    end

    context "when the lock is already acquired but by the same owner in a different instance" do

      let (:different_instance) { Mongo::Lock.release 'my_lock', owner: 'spence' }

      it "releases the lock" do
        lock
        different_instance.release
        expect(collection.find(key: 'my_lock', owner: 'spence').count).to be 0
      end

      it "returns true" do
        lock
        expect(different_instance.release).to be_true
      end

    end

    context "when the raise option is set to true" do

      let(:lock) { Mongo::Lock.new 'my_lock', raise: true, timeout_in: 0.1, frequency: 0.01  }

      context "when the lock isn't acquired and cant be" do

        it "raises Mongo::Lock::NotReleasedError" do
          collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.seconds.from_now
          expect{ lock.release }.to raise_error Mongo::Lock::NotReleasedError
        end

      end

    end

    context "when options are provided" do

      it "they override the defaults" do
        collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.seconds.from_now
        expect(lock.release owner: 'tobie').to be_true
        expect(collection.find(key: 'my_lock', owner: 'tobie').count).to be 0
      end

    end

  end

  describe '.release!' do

    it "calls .release with raise errors option set to true" do
      expect(Mongo::Lock).to receive(:init_and_send).with('my_lock', { owner: 'tobie' }, :release!)
      Mongo::Lock.release! 'my_lock', owner: 'tobie'
    end

  end

  describe '#release!' do

    it "calls .release with raise errors option set to true" do
      expect(lock).to receive(:release).with({ limit: 3, raise: true })
      lock.release! limit: 3
    end

  end

end
