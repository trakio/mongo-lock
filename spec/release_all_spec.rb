require 'spec_helper'

describe Mongo::Lock do

  describe '.release_all' do

    before :each do
      Mongo::Lock.configure collections: { default: collection, other: other_collection }
    end

    let!(:locks) do
      collection.insert key: 'tobies_lock', owner: 'tobie'
      collection.insert key: 'spences_lock', owner: 'spence'
      other_collection.insert key: 'spences_lock', owner: 'spence'
      another_collection.insert key: 'spences_lock', owner: 'spence'
    end

    it "removes all locks from the database" do
      Mongo::Lock.release_all
      expect(collection.count({ key: 'spences_lock', owner: 'spence'})).to eql 0
      expect(collection.count({ key: 'tobies_lock', owner: 'tobie'})).to eql 0
      expect(other_collection.count({ key: 'spences_lock', owner: 'spence'})).to eql 0
    end

    context "when an owner is provided" do

      before do
        Mongo::Lock.release_all owner: 'spence'
      end

      it "doesn't release locks belonging to other owners" do
        expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
      end

      it "does release locks belonging to that owner" do
        Mongo::Lock.release_all owner: 'spence'
        expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
        expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
      end

    end

    context "when a collection symbol is provided" do

      before do
        Mongo::Lock.release_all collection: :other
      end

      it "does release locks in that collection" do
        expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
      end

      it "doesn't release locks in other collections" do
        expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
        expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
      end

    end

    context "when a collection is provided" do

      before do
        Mongo::Lock.release_all collection: other_collection
      end

      it "does release locks in that collection" do
        expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
      end

      it "doesn't release locks in other collections" do
        expect(collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
        expect(collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
      end

    end

    context "when a collections are provided" do

      before do
        Mongo::Lock.release_all collections: [another_collection, other_collection]
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
          Mongo::Lock.release_all collections: { another_collection: another_collection, other_collection: other_collection }
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
