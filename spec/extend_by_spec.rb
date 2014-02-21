require 'spec_helper'

describe Mongo::Lock do

  describe '#extend_by' do

    context "when a time is provided" do

      it "extends the lock" do

      end

    end

    context "when the lock has expired" do

      it "returns false" do

      end

    end

    context "when the lock has not been aquired yet" do

      it "returns false" do

      end

    end

    context "when the raise option is set to true" do

      context "and the lock has expired" do

        it "raises a Mongo::Lock::NotExtendedError" do

        end

      end

      context "and the lock has not been aquired yet" do

        it "raises a Mongo::Lock::NotExtendedError" do

        end

      end

    end

    context "when options are provided" do

      it "they override the defaults" do

      end

    end

  end

  describe '#extend' do

    it "calls #extend_by with the default expires_after config setting" do

    end

    it "also passes options on" do

    end

  end

  describe '.extend_by!' do

    it "calls .extend_by with raise errors option set to true" do

    end

  end

  describe '#extend!' do

    it "calls .extend with raise errors option set to true" do

    end

  end

end
