module Scheduler
  module Schedulable

    ##
    # Possible schedulable statuses.
    STATUSES = [ :queued, :running, :completed, :warning, :error, :locked ]

    ##
    # Possible log levels.
    LOG_LEVELS = [ :debug, :info, :warn, :error ]

    def self.included(base)
      base.class_eval do
        include Mongoid::Document

        field :executable_class,        type: String
        field :args,                    type: Array,      default: []
        field :scheduled_at,            type: DateTime
        field :executed_at,             type: DateTime
        field :completed_at,            type: DateTime
        field :pid,                     type: Integer
        field :status,                  type: Symbol,     default: :queued
        field :logs,                    type: Array,      default: []
        field :progress,                type: Float,      default: 0.0
        field :error,                   type: String
        field :backtrace,               type: String

        scope :queued,      -> { where(status: :queued) }
        scope :running,     -> { where(status: :running) }
        scope :completed,   -> { where(status: :completed) }
        scope :to_check,    -> { where(status: :warning) }
        scope :in_error,    -> { where(status: :error) }
        scope :locked,      -> { where(status: :locked) }

        class << self
        
          ##
          # Returns possible statuses.
          #
          # @return [Array<Symbol>] possible statuses.
          def statuses
            Scheduler::Schedulable::STATUSES
          end

          ##
          # Returns possible log levels.
          #
          # @return [Array<Symbol>] possible log levels.
          def log_levels
            Scheduler::Schedulable::LOG_LEVELS
          end

          ##
          # Returns the corresponding log color if this level.
          #
          # @param [Symbol] level log level.
          #
          # @return [Symbol] the color.
          def log_color(level)
            case level
            when :debug then :green
            when :info then :cyan
            when :warn then :yellow
            when :error then :red
            end
          end

          ##
          # Creates an instance of this class and schedules the job.
          #
          # @param [String] executable_class the class of the job to run.
          # @param [Array] *job_args job arguments
          #
          # @return [Object] the created job.
          def schedule(executable_class, *job_args)
            self.create(executable_class: executable_class, args: job_args).schedule
          end

          ##
          # Creates an instance of this class and performs the job.
          #
          # @param [String] executable_class the class of the job to run.
          # @param [Array] *job_args job arguments
          #
          # @return [Object] the created job.
          def perform(executable_class, *job_args)
            self.create(executable_class: executable_class, args: job_args).perform
          end

        end

        ##
        # Gets executor job class.
        #
        # @return [Class] the executor job class.
        def executable_class
          Object.const_get self[:executable_class]
        end

        ##
        # Resets the job data.
        #
        # @return [Object] itself.
        def reset
          self.scheduled_at = Time.current
          self.logs = []
          self.progress = 0.0
          self.unset(:error)
          self.unset(:backtrace)
          self.unset(:completed_at)
          self.unset(:executed_at)
          self.save

          self
        end

        ##
        # Schedules the job.
        #
        # @return [Object] itself.
        def schedule
          self.status = :queued
          self.reset

          yield self if block_given?
          self.perform if Scheduler.perform_jobs_in_test_or_development?

          self
        end

        ##
        # Performs the job.
        #
        # @param [Integer] pid the executing pid.
        # @param [Boolean] reset whether to reset job data before performing.
        #
        # @return [Object] the instanced executable_class.
        def perform(pid = nil, reset = false)
          self.reset if reset

          job = self.executable_class.new(self)
          raise Scheduler::Error.new "#{self.executable_class} does not implement method 'call'. Please make "\
            "sure to implement it before performing the job." unless job.respond_to? :call
          self.status!(:running)
          self.update(pid: pid) if pid.present?
          begin
            catch :error do
              job.call(*self.args)
            end
          rescue StandardError => error
            self.status!(:error)
            self.log(:error, error.message)
            self.log(:error, error.backtrace.join("\n"))
          end
          self.completed_at = Time.current
          if self.status == :running
            self.progress!(100)
            self.status!(:completed)
          end

          self
        end

        ##
        # Immediately update the status to the given one.
        #
        # @param [Symbol] status the status to update.
        #
        # @return [nil]
        def status!(status)
          self.update(status: status)
        end

        ##
        # Immediately increases progress to the given amount.
        #
        # @param [Float] amount the given progress amount.
        def progress!(amount)
          self.update(progress: amount.to_f) if amount.numeric?
        end

        ##
        # Immediately increases progress by the given amount.
        #
        # @param [Float] amount the given progress amount.
        def progress_by!(amount)
          self.update(progress: progress + amount.to_f) if amount.numeric?
        end

        ##
        # Immediately stops job execution and logs the error.
        #
        # @param [String] message the error message.
        def error!(message)
          self.log :error, message
          self.status! :error
          throw :error
        end

        ##
        # Registers a log message with the given level.
        def log(level, message)
          raise Scheduler::Error.new "The given log level '#{level}' is not valid. "\
            "Valid log levels are: #{LOG_LEVELS.join(', ')}" unless level.in? LOG_LEVELS
          Scheduler.logger.send level, Rainbow("[#{self.class}:#{self.id}] #{message}").send(self.class.log_color level)
          self.update(logs: logs.push([level, message]))
        end
      end
    end

  end
end
