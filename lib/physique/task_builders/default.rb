module Physique
  class DefaultTasksBuilder < TasksBuilder
    def build_tasks
      Rake::Task.define_task :default => [ :test ]
      Rake::Task.define_task :ci => [ :versionizer, :test ]
    end
  end
end

