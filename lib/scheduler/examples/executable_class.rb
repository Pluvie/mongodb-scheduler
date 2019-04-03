module Scheduler
  module Examples
    class ExecutableClass

      def initialize(*args)
      end

      def call(job)
        job.log :info, 'Example of execution.'
      end
    end
  end
end
