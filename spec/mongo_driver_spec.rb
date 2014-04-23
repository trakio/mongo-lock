require 'spec_helper'
require 'mongo-lock/drivers/mongo'

describe Mongo::Lock::Drivers::Mongo do

  let(:collection1) { my_collection }
  let(:collection2) { other_collection }
  let(:collection3) { another_collection }

  configure_for_mongo

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