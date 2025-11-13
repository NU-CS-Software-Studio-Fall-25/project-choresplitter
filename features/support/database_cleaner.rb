begin
  require 'database_cleaner/active_record'
  DatabaseCleaner.strategy = :transaction
  Before do
    DatabaseCleaner.start
  end
  After do
    DatabaseCleaner.clean
  end
rescue NameError
  raise "You need to add database_cleaner-active_record to your Gemfile"
end
