module CruxRake
  module BuildTasksBuilder
    def add_build_tasks
      add_version_tasks
      add_compile_tasks
    end

    private

    def add_version_tasks
      require 'albacore/tasks/versionizer'
      Albacore::Tasks::Versionizer.new :versionizer
    end

    def add_compile_tasks
      task = add_build_task :compile => [ :restore ] do |b|
        b.target = %w(Clean Rebuild)
      end
      task.add_description 'Builds the solution'

      namespace :compile do
        @solution.compile.targets.each do |t|
          task = add_build_task t.downcase do |b|
            b.target = t
          end
          task.add_description "Builds the solution using the #{t} target"
        end
      end
    end

    def add_build_task(*args, &block)
      build_task *args do |b|
        configure_build b
        block.call b
      end
    end

    def configure_build(config)
      config.sln = @solution.file
      config.prop 'Configuration', @solution.compile.configuration
      config.logging = @solution.compile.logging
    end
  end
end