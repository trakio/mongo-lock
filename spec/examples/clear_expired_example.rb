shared_examples "MongoLock driver that can clear expired locks" do

  describe Mongo::Lock do

    describe '.clear_expired' do

      before :each do
        Mongo::Lock.configure collections: { default: collection1, other: collection2 }
      end

      let!(:locks) do
        my_collection.insert key: 'tobies_lock', owner: 'tobie', expires_at: 1.minute.from_now, ttl: 1.minute.from_now
        my_collection.insert key: 'spences_lock', owner: 'spence', expires_at: 1.minute.ago, ttl: 1.minute.ago
        other_collection.insert key: 'spences_lock', owner: 'spence', expires_at: 1.minute.ago, ttl: 1.minute.ago
        another_collection.insert key: 'spences_lock', owner: 'spence', expires_at: 1.minute.ago, ttl: 1.minute.ago
      end

      it "deletes expired locks in all reegistered collections" do
        Mongo::Lock.configure collections: { default: collection1, other: collection2 }
        other_collection.insert owner: 'owner', key: 'my_lock', expires_at: 1.minute.from_now
        Mongo::Lock.clear_expired
        expect(my_collection.find().count).to be 1
        expect(other_collection.find().count).to be 1
      end

      context "when a collection is provided" do

        before do
          Mongo::Lock.clear_expired collection: collection2
        end

        it "does release locks in that collection" do
          expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
        end

        it "doesn't release locks in other collections" do
          expect(my_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
          expect(my_collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
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
          expect(my_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
          expect(my_collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
        end

      end

      context "when collections are provided" do

        before do
          Mongo::Lock.clear_expired collections: [collection3, collection2]
        end

        it "does release locks in those collection" do
          expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
          expect(another_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
        end

        it "doesn't release locks in other collections" do
          expect(my_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
          expect(my_collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
        end

        context "when collections is provided as a hash" do

          before do
            Mongo::Lock.clear_expired collections: { another_collection: collection3, other_collection: collection2 }
          end

          it "does release locks in those collection" do
            expect(other_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
            expect(another_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 0
          end

          it "doesn't release locks in other collections" do
            expect(my_collection.find({ key: 'spences_lock', owner: 'spence'}).count).to eql 1
            expect(my_collection.find({ key: 'tobies_lock', owner: 'tobie'}).count).to eql 1
          end

        end

      end

    end

  end

end
