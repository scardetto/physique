module Physique
  class DefaultTasksBuilder < TasksBuilder
    def build_tasks
      task :default => [ :test ]
      task :ci => [ :versionizer, :test ]
    end
  end
end

