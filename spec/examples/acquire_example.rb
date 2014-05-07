shared_examples "MongoLock driver that can aquire locks" do

  describe Mongo::Lock do

    describe '.acquire' do

      it "creates and returns a new Mongo::Lock instance" do
        expect(Mongo::Lock.acquire 'my_lock').to be_a Mongo::Lock
      end

      it "calls #acquire to acquire the lock" do
        expect_any_instance_of(Mongo::Lock).to receive(:acquire)
        Mongo::Lock.acquire 'my_lock'
      end

      context "when options are provided" do

        it "passes them to the new lock" do
          lock = Mongo::Lock.acquire('my_lock', { limit: 3 })
          expect(lock.configuration.limit).to be 3
        end

      end

      context "when a block is provided" do

        it "passes it to the new lock" do
          block = Proc.new { |lock| }
          expect_any_instance_of(Mongo::Lock).to receive(:acquire).with( &block)
          lock = Mongo::Lock.acquire('my_lock', { limit: 3 }, &block)
        end

      end

    end

    describe '#acquire' do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence' }

      context "when lock is available" do

        it "acquires the lock" do
          lock.acquire
          expect(my_collection.find(key: 'my_lock').count).to be 1
        end

        it "sets the lock to expire" do
          lock.acquire
          expect(my_collection.find(key: 'my_lock').first['expires_at']).to be_within(1.second).of(10.seconds.from_now)
          expect(my_collection.find(key: 'my_lock').first['ttl']).to be_within(1.second).of(10.seconds.from_now)
        end

        it "returns true" do
          expect(lock.acquire).to be_true
        end

      end

      context "when the frequency option is a Proc" do

        let(:lock) { Mongo::Lock.new 'my_lock' }

        it "should call the Proc with the attempt number" do
          my_collection.insert key: 'my_lock', owner: 'tobie', expires_at: 10.seconds.from_now
          proc = Proc.new{ |x| x }
          expect(proc).to receive(:call).with(1).and_return(0.01)
          expect(proc).to receive(:call).with(2).and_return(0.01)
          expect(proc).to receive(:call).with(3).and_return(0.01)
          lock.acquire limit: 3, frequency: proc
        end

      end

      context "when the lock is unavailable" do

        it "retries until it can acquire it" do
          my_collection.insert key: 'my_lock', owner: 'tobie', expires_at: 0.1.seconds.from_now
          lock.acquire frequency: 0.01, timeout_in: 0.2, limit: 20
          expect(my_collection.find(key: 'my_lock', owner: 'spence').count).to be 1
        end

      end

      context "when the lock is already acquired but by the same owner" do

        before :each do
          my_collection.insert key: 'my_lock', owner: 'spence', expires_at: 10.minutes.from_now
        end

        it "doesn't create a new lock" do
          lock.acquire
          expect(my_collection.find(key: 'my_lock').count).to be 1
        end

        it "returns true" do
          expect(lock.acquire).to be_true
        end

        it "sets this instance as acquired" do
          lock.acquire
          expect(lock.instance_variable_get('@acquired')).to be_true
        end

        context "when a block is provided" do

          let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.2, limit: 11, frequency: 0.01, should_raise: true }

          it "should acquire the lock" do
            lock.acquire do |lock|
              expect(Mongo::Lock.available? 'my_lock', owner: 'tobie').to be_false
            end
          end

          it "should call the block" do
            expect{ |block| lock.acquire &block }.to yield_with_args lock
          end

          it "should release the lock" do
            lock.acquire do |lock|
              # Do something
            end
            expect(Mongo::Lock.available?('my_lock', owner: 'spence')).to be_true
          end

        end

      end

      context "when the lock cannot be acquired" do

        context "and acquisition timeout_in occurs" do

          let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.03, frequency: 0.01 }

          it "should return false" do
            my_collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.second.from_now
            expect(lock.acquire).to be_false
          end

        end

        context "and acquisition limit is exceeded" do

          let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence', timeout_in: 0.4, limit: 3, frequency: 0.01 }

          it "should return false" do
            my_collection.insert key: 'my_lock', owner: 'tobie', expires_at: 1.second.from_now
            expect(lock.acquire).to be_false
          end

        end

      end

      context "when the lock cannot be acquired and raise option is set to true" do

        context "and acquisition timeout_in occurs" do

          let(:lock) { Mongo::Lock.new 'my_lock', owner: 'tobie', timeout_in: 0.4, limit: 3, frequency: 0.01, should_raise: true }

          it "should raise Mongo::Lock::NotAcquiredError" do
            my_collection.insert key: 'my_lock', owner: 'spence', expires_at: 1.second.from_now
            expect{lock.acquire}.to raise_error Mongo::Lock::NotAcquiredError
          end

        end

        context "and acquisition limit is exceeded" do

          let(:lock) { Mongo::Lock.new 'my_lock', owner: 'tobie', timeout_in: 0.3, limit: 3, frequency: 0.01, should_raise: true }

          it "should raise Mongo::Lock::NotAcquiredError" do
            my_collection.insert key: 'my_lock', owner: 'spence', expires_at: 1.second.from_now
            expect{lock.acquire}.to raise_error Mongo::Lock::NotAcquiredError
          end

        end

      end

      context "when options are provided" do

        let(:lock) { Mongo::Lock.new 'my_lock', owner: 'tobie', timeout_in: 0.2, limit: 11, frequency: 0.01, should_raise: true }

        it "overrides the lock's" do
          my_collection.insert key: 'my_lock', owner: 'spence', expires_at: 1.second.from_now
          expect(lock.acquire timeout_in: 0.05, limit: 3, frequency: 0.02, should_raise: false).to be_false
        end

      end

      context "when a block is provided" do

        let(:lock) { Mongo::Lock.new 'my_lock', owner: 'tobie', timeout_in: 0.2, limit: 11, frequency: 0.01, should_raise: true }

        it "should acquire the lock" do
          lock.acquire do |lock|
            expect(Mongo::Lock.available? 'my_lock', owner: 'spence').to be_false
          end
        end

        it "should call the block" do
          expect{ |block| lock.acquire &block }.to yield_with_args lock
        end

        it "should release the lock" do
          lock.acquire do |lock|
            # Do something
          end
          expect(Mongo::Lock.available?('my_lock', owner: 'spence')).to be_true
        end

      end

    end

    describe '.acquire!' do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence' }

      it "calls .acquire with raise errors option set to true" do
        expect(Mongo::Lock).to receive(:init_and_send).with('my_lock', { limit: 3 }, :acquire!)
        Mongo::Lock.acquire! 'my_lock', limit: 3
      end

    end

    describe '#acquire!' do

      let(:lock) { Mongo::Lock.new 'my_lock', owner: 'spence' }

      it "calls #acquire with raise errors option set to true" do
        expect(lock).to receive(:acquire).with({ limit: 3, should_raise: true })
        lock.acquire! limit: 3
      end

    end

  end

end
