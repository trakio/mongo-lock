namespace :mongolock do
  desc "Remove all the expired locks from registered collections"
  task :clear_expired => :environment do
    ::Mongo::Lock.clear_expired
  end

  desc "Release all expired locks from registered collections"
  task :release_all => :environment do
    ::Mongo::Lock.release_all
  end

  desc "Release all expired locks from registered collections"
  task :ensure_indexes => :environment do
    ::Mongo::Lock.ensure_indexes
  end
end
