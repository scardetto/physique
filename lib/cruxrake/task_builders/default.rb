module CruxRake
  class DefaultTasksBuilder < TasksBuilder
    def build_tasks
      def add_default_tasks
        Rake::Task.define_task :default => [ :test ]
        Rake::Task.define_task :ci => [ :versionizer, :test ]
      end
    end
  end
end

