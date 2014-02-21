require 'spec_helper'

describe Mongo::Lock do

  describe '#available?' do

    context "when the lock is available" do

      it "returns true" do

      end

    end

    context "when the lock is expired" do

      it "returns true" do

      end

    end

    context "when the lock is already acquired but by this owner" do

      it "returns true" do

      end

    end

    context "when the lock is already acquired" do

      it "returns false" do

      end

    end

  end

end
