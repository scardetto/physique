require 'albacore/dsl'

# Reopen Albacore DSL to get at the pre-built tasks
# There is probably a better way to do this but ```me == :ruby_noob```
module Physique
  module DSL
    include Albacore::DSL

    private

    # A rake task type for executing sqlcmd
    def sqlcmd(*args, &block)
      require 'physique/tasks/sqlcmd'

      Albacore.define_task *args do |task_name, own_args|
        c = Physique::SqlCmd::Config.new
        yield c, own_args
        Physique::SqlCmd::Task.new(c.opts).execute
      end
    end

    # A rake task type for executing sqlcmd
    def fluent_migrator(*args, &block)
      require 'physique/tasks/fluent_migrator'

      Albacore.define_task *args do |task_name, own_args|
        c = Physique::FluentMigrator::Config.new
        yield c, own_args
        Physique::FluentMigrator::Task.new(c.opts).execute
      end
    end

    # A rake task type for executing sqlcmd
    def octopus_pack(*args, &block)
      require 'physique/tasks/octopus_pack'

      Albacore.define_task *args do |task_name, own_args|
        c = Physique::OctopusPack::Config.new
        yield c, own_args
        Physique::OctopusPack::Task.new(c.opts).execute
      end
    end
  end
end

self.extend Albacore::DSL
