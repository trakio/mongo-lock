require 'spec_helper'

describe Mongo::Lock do

  describe '.ensure_indexes' do

    context "when provided with a MongoDB collection" do

      before :each do
        Mongo::Lock.ensure_indexes
      end

      it "should build ttl index for each collection" do
        puts collection.index_information
        expect(collection.index_information['ttl_1']).to eql "v"=>1, "key"=> { "ttl"=>1 }, "ns"=>"mongo_lock_tests.locks", "name"=>"ttl_1", "expireAfterSeconds"=>0
      end

      it "should build an index on key and expires_at for each collection" do
        expect(collection.index_information['key_1_owner_1_expires_at_1']).to eql "v"=>1, "key"=> { "key"=>1, "owner"=>1, "expires_at"=>1 }, "ns"=>"mongo_lock_tests.locks", "name"=>"key_1_owner_1_expires_at_1"
      end

    end

  end

end
