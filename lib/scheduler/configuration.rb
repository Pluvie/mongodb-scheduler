module Scheduler
  class Configuration

    # @return [String] envinronment of your app
    attr_accessor :environment
    # @return [String] a path to Mongoid config file.
    attr_accessor :mongoid_config_file
    # @return [String] a path to the specified log file.
    attr_accessor :log_file
    # @return [Class] the class of the main job model.
    attr_accessor :job_class
    # @return [Integer] how much time to wait before each iteration.
    attr_accessor :polling_interval
    # @return [Integer] maximum number of concurent jobs.
    attr_accessor :max_concurrent_jobs
    # @return [Proc] whether to perform jobs when in test or development env.
    attr_accessor :perform_jobs_in_test_or_development

    def initialize
      @environment = 'test'
      @mongoid_config_file = File.join(Scheduler.root, 'spec/mongoid.yml')
      @log_file = STDOUT
      @job_class = Scheduler::Examples::SchedulableModel
      @polling_interval = 5
      @max_concurrent_jobs = [ Etc.nprocessors, 24 ].min
      @perform_jobs_in_test_or_development = false
    end

  end
end
