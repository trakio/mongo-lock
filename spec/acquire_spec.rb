require 'spec_helper'

describe Mongo::Lock do

  describe '.acquire' do

    it "creates and returns a new Mongo::Lock instance" do
      expect(Mongo::Lock.acquire 'my_lock').to be_a Mongo::Lock
    end

    it "calls #acquire! to acquire the lock" do
      expect(Mongo::Lock.acquire 'my_lock').to be_a Mongo::Lock
    end

    context "when a collection is not provided" do

      it "raises an exception" do

      end

    end

    context "when options are provided" do

      it "passes them to the new lock" do

      end

    end

  end

  describe '#acquire' do

    context "when lock is available" do

      it "acquires the lock" do

      end

      it "sets the lock to expire" do

      end

      it "returns true" do

      end

    end

    context "when the frequency option is a Proc" do

      it "should call the Proc with the attempt number" do

      end

    end

    context "when the lock is unavailable" do

      it "retries until it can acquire it" do

      end

    end

    context "when the lock is already acquired but by the same owner" do

      it "sets this instance as acquired" do

      end

      it "returns true" do

      end

    end

    context "when the lock cannot be acquired" do

      context "and acquisition timeout occurs" do

        it "should return false" do

        end

      end

      context "and acquisition limit is exceeded" do

        it "should return false" do

        end

      end

    end

    context "when the lock cannot be acquired and raise option is set to true" do

      context "and acquisition timeout occurs" do

        it "should raise Mongo::Lock::NotAcquiredError" do

        end

      end

      context "and acquisition limit is exceeded" do

        it "should raise Mongo::Lock::NotAcquiredError" do

        end

      end

    end

    context "when options are provided" do

      it "overrides the lock's" do

      end

    end

  end

  describe '.acquire!' do

    it "calls .acquire with raise errors option set to true" do

    end

  end

  describe '#acquire!' do

    it "calls .acquire with raise errors option set to true" do

    end

  end

  describe '.lock' do

    it "calls .acquire" do

    end

  end

  describe '#lock' do

    it "calls #acquire" do

    end

  end


  describe '.lock!' do

    it "calls .acquire!" do

    end

  end

  describe '#lock!' do

    it "calls #acquire!" do

    end

  end

end
