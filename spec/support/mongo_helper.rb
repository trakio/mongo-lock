module MongoHelper

  def configure_for_mongo
    before :each do
      Mongo::Lock.configure collections: {}
      database.drop_collection("locks")
      database.drop_collection("other_locks")
      database.drop_collection("another_locks")
      Mongo::Lock.configure collection: my_collection
    end
  end

  def connection
    @connection ||= Mongo::Connection.new("localhost")
  end

  def database
    @database ||= connection.db("mongo_lock_tests")
  end

  def my_collection
    @my_collection ||= database.collection :locks
  end

  def other_collection
    @other_collection ||= database.collection :other_locks
  end

  def another_collection
    @another_collection ||= database.collection :another_locks
  end

  def configure_for_moped
    before :each do
      Mongo::Lock.configure collections: {}
      database.drop_collection("locks")
      database.drop_collection("other_locks")
      database.drop_collection("another_locks")
      Mongo::Lock.configure collection: my_moped_collection
    end
  end

  def moped_connection
    @moped_connection ||= Moped::Session.new([ "127.0.0.1:27017" ])
  end

  def moped_database
    moped_connection.use "mongo_lock_tests"
    moped_connection
  end

  def my_moped_collection
    @my_moped_collection ||= moped_database[:locks]
  end

  def other_moped_collection
    @other_moped_collection ||= moped_database[:other_locks]
  end

  def another_moped_collection
    @another_moped_collection ||= moped_database[:another_locks]
  end

end