require 'spec_helper'
require 'mongo-lock/drivers/moped'

describe Mongo::Lock::Drivers::Moped do

  let(:collection1) { my_moped_collection }
  let(:collection2) { other_moped_collection }
  let(:collection3) { another_moped_collection }

  configure_for_moped

  it_behaves_like "MongoLock driver that can aquire locks"
  it_behaves_like "MongoLock driver that can find if a lock is acquired"
  it_behaves_like "MongoLock driver that can find if a lock is available"
  it_behaves_like "MongoLock driver that can clear expired locks"
  it_behaves_like "MongoLock driver that can ensure indexes"
  it_behaves_like "MongoLock driver that can find if a lock have expired"
  it_behaves_like "MongoLock driver that can extend locks"
  it_behaves_like "MongoLock driver that can release all locks"
  it_behaves_like "MongoLock driver that can release locks"

end