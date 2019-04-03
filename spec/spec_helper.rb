require "bundler/setup"
require "scheduler"
require "mongoid"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Loads Mongoid for persistence
  Mongoid.load!(Scheduler.configuration.mongoid_config_file, Scheduler.env)

  # Sets a test log file
  Scheduler.configure do |config|
    config.log_file = File.join(Scheduler.root, "log/test.log")
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
