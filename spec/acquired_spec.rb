require 'spec_helper'

describe Mongo::Lock do

  describe '#acquired?' do

    context "when the lock has been acquired" do

      it "returns true" do

      end

    end

    context "when the lock hasn't been acquired" do

      it "returns false" do

      end

    end

    context "when the lock is already acquired but by the same owner in a different thread" do

      it "sets this instance as acquired" do

      end

      it "returns true" do

      end

    end

    context "when the lock was acquired but has since expired" do

      it "returns false" do

      end

    end

    context "when the lock was acquired but has since been released" do

      it "returns false" do

      end

    end

  end

end
