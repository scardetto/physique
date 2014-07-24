require 'albacore/dsl'

# Reopen Albacore DSL to get at the pre-built tasks
# There is probably a better way to do this but ```me == :ruby_noob```
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

    def nugets_pack_task(*args, &block)
      nugets_pack *args, &block
    end

    def octopus_pack_task(*args, &block)
      octopus_pack *args, &block
    end

    private

    # A rake task type for executing sqlcmd
    def sqlcmd(*args, &block)
      require 'physique/tasks/sqlcmd'

      Albacore.define_task *args do
        c = Physique::SqlCmd::Config.new
        yield c
        Physique::SqlCmd::Task.new(c.opts).execute
      end
    end

    # A rake task type for executing sqlcmd
    def fluent_migrator(*args, &block)
      require 'physique/tasks/fluent_migrator'

      Albacore.define_task *args do
        c = Physique::FluentMigrator::Config.new
        yield c
        Physique::FluentMigrator::Task.new(c.opts).execute
      end
    end

    # A rake task type for executing sqlcmd
    def octopus_pack(*args, &block)
      require 'physique/tasks/octopus_pack'

      Albacore.define_task *args do
        c = Physique::OctopusPack::Config.new
        yield c
        Physique::OctopusPack::Task.new(c.opts).execute
      end
    end
  end
end

self.extend Albacore::DSL
