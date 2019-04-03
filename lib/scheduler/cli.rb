require "hanami/cli"

module Scheduler
  class CLI
    def call(*args)
      Hanami::CLI.new(Commands).call(*args)
    end

    module Commands
      extend Hanami::CLI::Registry

      class Start < Hanami::CLI::Command
        def call(*)
          Scheduler.start
        end
      end
      class Stop < Hanami::CLI::Command
        def call(*)
          Scheduler.stop
        end
      end
      class Restart < Hanami::CLI::Command
        def call(*)
          Scheduler.restart
        end
      end

      register "start", Start
      register "stop", Stop
      register "restart", Restart
    end
  end
end
