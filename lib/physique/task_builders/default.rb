module Physique
  class DefaultTasksBuilder < TasksBuilder

    def build_phases
      task :version
      task :restore => [ :version ]
      task :compile => [ :restore ]
      task :test    => [ :compile ]
      task :package => [ :test ]
      task :publish => [ :package ]
      task :default => [ :test ]
    end

    def build_tasks
      task :default => [ :test ]
    end
  end
end

