# Reopen Albacore DSL to get at the pre-built tasks
# There is probably a better way to do this but ```me == ruby_noob```
module Albacore
  module DSL
    def asmver_task(*args, &block)
      asmver *args, &block
    end

    def build_task(*args, &block)
      build *args, &block
    end

    def nugets_restore_task(*args, &block)
      nugets_restore *args, &block
    end

    def test_runner_task(*args, &block)
      test_runner *args, &block
    end

    def sqlcmd_task(*args, &block)
      sqlcmd *args, &block
    end

    def fluent_migrator_task(*args, &block)
      fluent_migrator *args, &block
    end

    def octopus_pack_task(*args, &block)
      octopus_pack *args, &block
    end

    private

    # A rake task type for executing sqlcmd
    def sqlcmd(*args, &block)
      require 'cruxrake/tasks/sqlcmd'

      Albacore.define_task *args do
        c = CruxRake::SqlCmd::Config.new
        block.call c
        CruxRake::SqlCmd::Task.new(c.opts).execute
      end
    end

    # A rake task type for executing sqlcmd
    def fluent_migrator(*args, &block)
      require 'cruxrake/tasks/fluent_migrator'

      Albacore.define_task *args do
        c = CruxRake::FluentMigrator::Config.new
        block.call c
        CruxRake::FluentMigrator::Task.new(c.opts).execute
      end
    end

    # A rake task type for executing sqlcmd
    def octopus_pack(*args, &block)
      require 'cruxrake/tasks/octopus_pack'

      Albacore.define_task *args do
        c = CruxRake::OctopusPack::Config.new
        block.call c
        CruxRake::OctopusPack::Task.new(c.opts).execute
      end
    end
  end
end

self.extend Albacore::DSL
