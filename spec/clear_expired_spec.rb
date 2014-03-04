require 'spec_helper'

describe Mongo::Lock do

  describe '.clear_expired' do

    before :each do
      Mongo::Lock.configure collections: { default: collection, other: other_collection }
    end

    let!(:locks) do
      collection.insert key: 'tobies_lock', owner: 'tobie', expires_at: 1.minute.from_now, ttl: 1.minute.from_now
      collection.insert key: 'spences_lock', owner: 'spence', expires_at: 1.minute.ago, ttl: 1.minute.ago
      other_collection.insert key: 'spences_lock', owner: 'spence', expires_at: 1.minute.ago, ttl: 1.minute.ago
      another_collection.insert key: 'spences_lock', owner: 'spence', expires_at: 1.minute.ago, ttl: 1.minute.ago
    end

    it "deletes expired locks in all reegistered collections" do
      Mongo::Lock.configure collections: { default: collection, other: other_collection }
      other_collection.insert owner: 'owner', key: 'my_lock', expires_at: 1.minute.from_now
      Mongo::Lock.clear_expired
      expect(collection.find().count).to be 1
      expect(other_collection.find().count).to be 1
    end

    context "when a collection is provided" do

      before do
        Mongo::Lock.clear_expired collection: other_collection
      end

      it "does release locks in that collection" do
        expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
      end

      it "doesn't release locks in other collections" do
        expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
        expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
      end

    end

    context "when a collection symbol is provided" do

      before do
        Mongo::Lock.clear_expired collection: :other
      end

      it "does release locks in that collection" do
        expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
      end

      it "doesn't release locks in other collections" do
        expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
        expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
      end

    end

    context "when collections are provided" do

      before do
        Mongo::Lock.clear_expired collections: [another_collection, other_collection]
      end

      it "does release locks in those collection" do
        expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
        expect(another_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
      end

      it "doesn't release locks in other collections" do
        expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
        expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
      end

      context "when collections is provided as a hash" do

        before do
          Mongo::Lock.clear_expired collections: { another_collection: another_collection, other_collection: other_collection }
        end

        it "does release locks in those collection" do
          expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
          expect(another_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
        end

        it "doesn't release locks in other collections" do
          expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
          expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
        end

      end

    end

  end

end
