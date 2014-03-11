require 'spec_helper'

describe Mongo::Lock::Configuration do

  subject { Mongo::Lock::Configuration.new({}, {}) }

  let (:collections_with_default) { { a: 'a', b: 'b', default: my_collection } }
  let (:collections) { { a: 'a', b: 'b' } }
  let (:my_collection) { 'default' }

  describe '#initialize' do

    context "when provided with a hash" do

      it "sets each value" do
        config = Mongo::Lock::Configuration.new({}, { limit: 3, timeout_in: 4 })
        expect(config.limit).to be 3
        expect(config.timeout_in).to be 4
      end

      context "when provided with a default connection" do

        it "stores it in the connections hash as :default" do
          config = Mongo::Lock::Configuration.new({}, { collection: my_collection, collections: collections })
          expect(config.collections).to eql collections_with_default
        end

      end

    end

    context "when provided with a default" do

      it "sets each value" do
        config = Mongo::Lock::Configuration.new({ limit: 3, timeout_in: 4 }, { limit: 5 })
        expect(config.limit).to be 5
        expect(config.timeout_in).to be 4
      end

      context "when provided with a default connection" do

        it "stores it in the connections hash as :default" do
          config = Mongo::Lock::Configuration.new({ collections: collections }, { collection: my_collection})
          expect(config.collections).to eql collections_with_default
        end

      end

    end

  end

  describe "#collections=" do

    it "should set collections hash" do
      subject.collections = collections
      expect(subject.instance_variable_get('@collections')).to be collections
    end

    it "should remove default from collections hash" do
      subject.instance_variable_set('@collections', collections_with_default)
      subject.collections = collections
      expect(subject.instance_variable_get('@collections')).to be collections
    end

  end

  describe "#set_collections_keep_default" do

    it "should keep default in the collections hash" do
      subject.instance_variable_set('@collections', collections_with_default)
      subject.set_collections_keep_default collections
      expect(subject.instance_variable_get('@collections')).to eql collections_with_default
    end

  end

  describe "#collections" do

    it "should return the collections hash" do
      subject.instance_variable_set('@collections', collections)
      expect(subject.collections).to be collections
    end

  end

  describe "#collection=" do

    it "should set the default collection" do
      subject.collection = my_collection
      expect(subject.instance_variable_get('@collections')[:default]).to be my_collection
    end

  end

  describe "#collection" do

    context "when a symbol is provided" do

      it "should return that collection" do
        subject.instance_variable_set('@collections', collections)
        expect(subject.collection :a).to eql 'a'
      end

    end

    context "when a string is provided" do

      it "should return that collection" do
        subject.instance_variable_set('@collections', collections)
        expect(subject.collection 'a').to eql 'a'
      end

    end

    context "when it's any other object is" do

      it "should return that collection" do
        my_collection = Object.new
        subject.instance_variable_set('@collections', collections)
        expect(subject.collection my_collection).to be my_collection
      end

    end

    context "when a symbol isn't provided" do

      it "should return the default collection" do
        subject.instance_variable_set('@collections', collections_with_default)
        expect(subject.collection).to eql 'default'
      end

    end

  end

  describe "#timeout_in=" do

    it "should set the timeout_in value" do
      subject.timeout_in = 123
      expect(subject.instance_variable_get('@timeout_in')).to be 123
    end

  end

  describe "#timeout_in" do

    it "should return the timeout_in value" do
      subject.instance_variable_set('@timeout_in', 456)
      expect(subject.timeout_in).to be 456
    end

  end

  describe "#limit=" do

    it "should set the limit value" do
      subject.limit = 7
      expect(subject.instance_variable_get('@limit')).to be 7
    end

  end

  describe "#limit" do

    it "should return the limit value" do
      subject.instance_variable_set('@limit', 8)
      expect(subject.limit).to be 8
    end

  end

  describe "#frequency=" do

    it "should set the frequency value" do
      subject.frequency = 9
      expect(subject.instance_variable_get('@frequency')).to be 9
    end

  end

  describe "#frequency" do

    it "should return the frequency value" do
      subject.instance_variable_set('@frequency', 1)
      expect(subject.frequency).to be 1
    end

  end

  describe "#expire_in=" do

    it "should set the expire_in value" do
      subject.expire_in = 9
      expect(subject.instance_variable_get('@expire_in')).to be 9
    end

  end

  describe "#expire_in" do

    it "should return the expire_in value" do
      subject.instance_variable_set('@expire_in', 1)
      expect(subject.expire_in).to be 1
    end

  end

  describe "#owner" do

    it "should return the owner value" do
      subject.instance_variable_set('@owner', 'spence')
      expect(subject.owner).to eql 'spence'
    end

    context "when owner is a Proc" do

      it "is called" do
        proc = Proc.new { }
        expect(proc).to receive(:call)
        subject.instance_variable_set('@owner', proc)
        subject.owner
      end

    end

  end

  describe "#owner=" do

    it "should set the owner value" do
      subject.owner = 'spence'
      expect(subject.instance_variable_get('@owner')).to eql 'spence'
    end

  end

end
