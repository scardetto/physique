module Physique
  class CompileConfig
    attr_writer :configuration, # Build configuration (Release, Debug, etc.)
                :logging        # MSBuild Logging level (normal, verbose, etc.)

    def initialize
      @targets = []
    end

    def add_target(val)
      @targets << val
    end

    def opts
      @targets = %w(Clean Build Rebuild) if @targets.blank?

      Map.new({
        configuration: @configuration,
        logging: @logging,
        targets: @targets
      }).apply(
        configuration: 'Release',
        logging: 'normal'
      )
    end
  end

  class BuildTasksBuilder < TasksBuilder
    def build_tasks
      add_version_task
      add_compile_tasks
    end

    private

    def add_version_task
      require 'albacore/tasks/versionizer'
      Albacore::Tasks::Versionizer.new :versionizer
    end

    def add_compile_tasks
      block = lambda &method(:configure_build)

      desc 'Builds the solution'
      build :compile => [ :restore ], &block.curry.(%w(Clean Rebuild))

      namespace :compile do
        solution.compile.targets.each do |t|
          desc "Builds the solution using the #{t} target"
          build t.downcase, &block.curry.(t)
        end
      end
    end

    def configure_build(target, config)
      config.sln = solution.file
      config.prop 'Configuration', solution.compile.configuration
      config.logging = solution.compile.logging
      config.target = target
    end
  end
end