require "rainbow"
require "logger"
require "mongoid"
require_relative "scheduler/version"
require_relative "scheduler/schedulable"
require_relative "scheduler/examples/schedulable_model"
require_relative "scheduler/examples/executable_class"
require_relative "scheduler/cli"
require_relative "scheduler/configuration"
require_relative "scheduler/main_process"

module Scheduler
  class Error < StandardError; end

  class << self

    # @return [Scheduler::Configuration] the configuration class for Scheduler.
    attr_accessor :configuration

    ##
    # Initializes configuration.
    #
    # @return [Scheduler::Configuration] the configuration class for Scheduler.
    def configuration
      @configuration || Scheduler::Configuration.new
    end

    ##
    # Method to configure various Scheduler options.
    #
    # @return [nil]
    def configure
      @configuration ||= Scheduler::Configuration.new
      yield @configuration
    end

    ##
    # Returns Scheduler gem root path.
    #
    # @return [String] Scheduler gem root path.
    def root
      File.dirname __dir__
    end

    ##
    # Returns current environment.
    #
    # @return [String] Scheduler environment.
    def env
      Scheduler.configuration.environment
    end

    ##
    # Gets scheduler pid file.
    #
    # @return [String] the pid file.
    def pid_file
      '/tmp/scheduler.pid'
    end

    ##
    # Gets scheduler main process pid.
    #
    # @return [Integer] main process pid.
    def pid
      File.read(self.pid_file).to_i rescue nil
    end

    ##
    # Checks whether to run jobs in test or development.
    #
    # @return [Boolean] to run jobs.
    def perform_jobs_in_test_or_development?
      Scheduler.configuration.perform_jobs_in_test_or_development
    end

    ##
    # Return the Scheduler logger.
    #
    # @return [Logger] the configured logger.
    def logger
      @@logger ||= Logger.new Scheduler.configuration.log_file
    end

    ##
    # Starts a Scheduler::MainProcess in a separate process.
    #
    # @return [nil]
    def start
      logger.info Rainbow("[Scheduler:#{Process.pid}] Starting..").cyan
      scheduler_pid = Process.fork do
        begin
          logger.info Rainbow("[Scheduler:#{Process.pid}] Forked.").cyan
          Process.daemon true, true
          logger.info Rainbow("[Scheduler:#{Process.pid}] Going into background..").cyan
          File.open(self.pid_file, 'w+') do |pidfile|
            pidfile.puts Process.pid
          end
          scheduler = Scheduler::MainProcess.new
        rescue StandardError => error
          puts Rainbow("#{error.class}: #{error.message} (#{error.backtrace.first})").red
        end
      end
      Process.detach(scheduler_pid)
      scheduler_pid
    end

    ##
    # Reschedules all running jobs and stops the scheduler main process.
    #
    # @return [nil]
    def stop
      begin
        Process.kill :TERM, Scheduler.pid
        FileUtils.rm(self.pid_file)
      rescue TypeError, Errno::ENOENT, Errno::ESRCH
      end
    end

    ##
    # Restarts the scheduler.
    #
    # @return [nil]
    def restart
      self.stop
      self.start
    end

  end

end
