require 'spec_helper'

describe Mongo::Lock do

  describe '.clear_expired' do

    it "deletes expired locks in all collections" do
      Mongo::Lock.configure collections: { default: collection, other: other_collection }
      collection.insert owner: 'owner', key: 'my_lock', expires_at: 1.minute.from_now
      collection.insert owner: 'owner', key: 'my_lock', expires_at: 1.minute.ago
      other_collection.insert owner: 'owner', key: 'my_lock', expires_at: 1.minute.from_now
      other_collection.insert owner: 'owner', key: 'my_lock', expires_at: 1.minute.ago
      Mongo::Lock.clear_expired
      expect(collection.find().count).to be 1
      expect(other_collection.find().count).to be 1
    end

  end

end
