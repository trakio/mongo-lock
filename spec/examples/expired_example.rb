shared_examples "MongoLock driver that can find if a lock have expired" do

  describe Mongo::Lock do

    describe '#expired?' do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.01, frequency: 0.01 }

      context "when the lock has not been acquired" do

        it "returns false" do
          sleep 0.02
          expect(lock.expired?).to be_false
        end

      end

      context "when the lock has expired" do

        it "returns true" do
          lock.acquire expire_in: 0.01
          sleep 0.02
          expect(lock.expired?).to be_true
        end

      end

      context "when the lock hasn't expired" do

        it "returns false" do
          lock.acquire expire_in: 0.1
          expect(lock.expired?).to be_false
        end

      end

    end

  end

end
