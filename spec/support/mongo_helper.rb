module MongoHelper

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

end