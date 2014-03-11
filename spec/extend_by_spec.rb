require 'spec_helper'

describe Mongo::Lock do

  let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01, expire_in: 1 }

  describe '#extend_by' do

    context "when a time is provided" do

      it "extends the lock" do
        lock.acquire
        lock.extend_by 60
        expect(my_collection.find(owner: 'spence', key: 'my_lock').first['expires_at']).to be_within(1.second).of(60.seconds.from_now)
      end

      it "returns true" do
        lock.acquire
        expect(lock.extend_by 50).to be_true
      end

    end

    context "when the lock has expired" do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01, expire_in: 0.11 }

      it "returns false" do
        lock.acquire
        sleep 0.11
        expect(lock.extend_by 10).to be_false
      end

    end

    context "when the lock has not been aquired yet" do

      it "returns false" do
        lock
        expect(lock.extend_by 10).to be_false
      end

    end

    context "when the lock has been released" do

      it "returns false" do
        lock.acquire
        lock.release
        expect(lock.extend_by 10).to be_false
      end

    end

    context "when the raise option is set to true" do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01, expire_in: 0.01, raise: true }

      context "and the lock has expired" do

        it "raises a Mongo::Lock::NotExtendedError" do
          lock.acquire
          sleep 0.02
          expect{lock.extend_by 10}.to raise_error Mongo::Lock::NotExtendedError
        end

      end

      context "and the lock has not been aquired yet" do

        it "raises a Mongo::Lock::NotExtendedError" do
          lock
          expect{lock.extend_by 10}.to raise_error Mongo::Lock::NotExtendedError
        end

      end

      context "and the lock has been released" do

        it "raises a Mongo::Lock::NotExtendedError" do
          lock.acquire
          lock.release
          expect{lock.extend_by 10}.to raise_error Mongo::Lock::NotExtendedError
        end

      end

    end

    context "when options are provided" do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01, raise: true }

      it "they override the defaults" do
        lock
        expect(lock.extend_by 10, raise: false).to be_false
      end

    end

  end

  describe '#extend' do

    it "calls #extend_by with the default expire_in config setting" do
      expect(lock).to receive(:extend_by).with(lock.configuration.expire_in, {})
      lock.extend
    end

    it "also passes options on" do
      expect(lock).to receive(:extend_by).with(lock.configuration.expire_in, { raise: true })
      lock.extend raise: true
    end

  end

  describe '.extend_by!' do

    it "calls .extend_by with raise errors option set to true" do
      expect(lock).to receive(:extend_by).with( 10, { raise: true })
      lock.extend_by! 10
    end

  end

  describe '#extend!' do

    it "calls .extend with raise errors option set to true" do
      expect(lock).to receive(:extend_by).with(lock.configuration.expire_in, { raise: true })
      lock.extend!
    end

  end

end
