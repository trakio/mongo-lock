module MongoHelper

  def connection
    @connection ||= Mongo::Connection.new("localhost")
  end

  def database
    @database ||= connection.db("mongo_lock_tests")
  end

  def collection
    @collection ||= database.collection :locks
  end

  def other_collection
    @other_collection ||= database.collection :other_locks
  end

end