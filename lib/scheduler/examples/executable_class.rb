module Scheduler
  module Examples
    class ExecutableClass

      def initialize(job)
        @job = job
      end

      def call(*args)
        @job.log :info, 'Example of execution.'
      end
    end
  end
end
