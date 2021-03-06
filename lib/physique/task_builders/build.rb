module Physique
  class CompileConfig
    attr_writer :default_targets, # Default build targets for compile task
                :configuration,   # Build configuration (Release, Debug, etc.)
                :logging          # MSBuild Logging level (normal, verbose, etc.)

    def initialize
      @default_targets = %w(Rebuild)
      @targets = %w(Clean Build Rebuild)
      @props = {}
    end

    def disable_versioning
      @disable_versioning = true
    end

    def clear_targets
      @targets.clear
    end

    def add_target(val)
      @targets << val
    end

    def prop(name, value)
      @props[name] = value
    end

    def opts
      raise ArgumentError, 'You must specify the default targets' if @default_targets.blank?

      Map.new({
        default_targets: @default_targets,
        configuration: @configuration,
        logging: @logging,
        targets: @targets,
        disable_versioning: !!@disable_versioning,
        props: @props
      }).apply(
        configuration: 'Release',
        logging: 'minimal'
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
      return if solution.compile.disable_versioning

      require 'albacore/tasks/versionizer'
      Albacore::Tasks::Versionizer.new :versionizer
    end

    def add_compile_tasks
      block = lambda(&method(:configure_build))

      desc 'Builds the solution'
      build :compile => [ :restore ], &block.curry.(solution.compile.default_targets)

      namespace :compile do
        solution.compile.targets.each do |t|
          desc "Builds the solution using the #{t} target"
          build t.downcase, &block.curry.(t)
        end
      end
    end

    def configure_build(target, config, _args)
      config.sln = solution.file
      config.prop 'Configuration', solution.compile.configuration
      config.logging = solution.compile.logging
      config.target = target

      solution.compile.props.each do |k,v|
        config.prop k, v
      end
    end
  end
end
