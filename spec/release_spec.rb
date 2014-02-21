require 'spec_helper'

describe Mongo::Lock do

  describe '.release' do

    it "creates a new Mongo::Lock instance" do

    end

    it "calls #release to release the lock" do

    end

    context "when a collection is not provided" do

      it "raises a Mongo::Lock::CollectionError" do

      end

    end

    context "when options are provided" do

      it "passes them to the new lock" do

      end

    end

  end

  describe '#release' do

    context "when lock is acquired" do

      it "releases the lock" do

      end

      it "returns true" do

      end

    end

    context "when the lock isn't acquired" do

      it "returns false" do

      end

    end

    context "when the lock was acquired but has since expired" do

      it "returns true" do

      end

    end

    context "when the lock was acquired but has already been released" do

      it "returns true" do

      end

    end

    context "when the lock is already acquired but by the same owner in a different thread" do

      it "releases the lock" do

      end

      it "returns true" do

      end

    end

    context "when the raise option is set to true" do

      context "and the lock has not been aquired yet" do

        it "raises a Mongo::Lock::NotReleasedError" do

        end

      end

    end

    context "when options are provided" do

      it "they override the defaults" do

      end

    end

  end

  describe '.release!' do

    it "calls .release with raise errors option set to true" do

    end

  end

  describe '#release!' do

    it "calls .release with raise errors option set to true" do

    end

  end

  describe '.unlock' do

    it "calls .release" do

    end

    it "passes on options" do

    end

  end

  describe '#unlock' do

    it "calls #release" do

    end

    it "passes on options" do

    end

  end


  describe '.unlock!' do

    it "calls .release!" do

    end

  end

  describe '#unlock!' do

    it "calls #release!" do

    end

  end

end
