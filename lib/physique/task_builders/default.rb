module Physique
  class DefaultTasksBuilder < TasksBuilder
    def build_tasks
      task :default => [ :test ]
    end
  end
end

