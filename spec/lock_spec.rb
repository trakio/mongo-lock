require 'spec_helper'

describe Mongo::Lock do

  describe '.lock' do

    it "locks the provided key" do
      true.should be_true
    end

  end

  describe '#lock' do

    it "locks the provided key" do
      true.should be_false
    end

  end

end
