require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 'albacore/config_dsl'
require 'cruxrake/project'

module CruxRake
  class SolutionConfig
    self.extend Albacore::ConfigDSL
    include Albacore::Logging

    # Path to the solution file
    attr_path_accessor :file

    def initialize
      @file = nil
      @compilation = CompileConfig.new
      @nuget = NugetConfig.new
      @tests = TestConfig.new
    end

    def use_nuget
      yield @nuget
    end

    def compile
      yield @compilation
    end

    def run_tests
      yield @tests
    end

    def database
      @migrator = FluentMigratorConfig.new
      yield @migrator
    end

    def octopus_deploy
      @octopus = OctopusDeployConfig.new
      yield @octopus
    end

    def opts
      Map.new({
        file: @file,
        nuget: @nuget.opts && @nuget.opts,
        compile: @compilation && @compilation.opts,
        test: @tests && @tests.opts,
        migrator: @migrator && @migrator.opts,
        octopus: @octopus && @octopus.opts,
      })
    end
  end

  class CompileConfig
    # Build configuration
    attr_writer :configuration

    # Logging
    attr_writer :logging

    def initialize
      @configuration = 'Release'
      @logging = 'normal'
      @targets = []
    end

    def add_target(val)
      @targets << val
    end

    def opts
      Map.new({
        configuration: @configuration,
        logging: @logging,
      }).apply(
        targets: %w(Clean Build Rebuild)
      )
    end
  end

  class NugetConfig
    self.extend Albacore::ConfigDSL

    # Path to nuget executable
    attr_path :exe

    # Path where nuget packages will be downloaded
    attr_path :restore_location

    # Path where nuget packages will be built
    attr_path :build_location

    # Disable package analysis (sets -NoPackageAnalysis flag)
    def disable_package_analysis
      @disable_package_analysis = true
    end

    def initialize
      @exe = 'src/.nuget/NuGet.exe'
      @restore_location = 'src/packages'
      @build_location = 'build/packages'
    end

    def opts
      Map.new({
        exe: @exe,
        restore_location: @restore_location,
        build_location: @build_location,
        disable_package_analysis: !!@disable_package_analysis
      })
    end
  end

  class TestConfig
    self.extend Albacore::ConfigDSL

    # Path to test runner executable
    attr_path :exe

    # Path to test runner executable
    attr_writer :files

    def initialize

    end

    def opts
      Map.new({
        exe: @exe,
        files: @files
      })
    end
  end

  class FluentMigratorConfig
    self.extend Albacore::ConfigDSL
    include Albacore::Logging

    # Project name or path
    attr_path :project

    # Programming language of the db project
    attr_writer :lang

    # Server instance name
    attr_writer :instance

    # Database name
    attr_writer :name

    # Scripts folder to examine to create tasks
    attr_writer :scripts_dir

    # Scripts folder to examine to create tasks
    attr_writer :dialect

    def initialize
      @lang = :cs
      @scripts_dir = '_Scripts'
    end

    def opts
      Map.new({
        exe: @exe,
        instance: @instance,
        name: @name,
        project: @project,
        project_file: CruxRake::Project.get_path(@project, @lang),
        lang: @lang,
      }).apply(
        lang: :cs,
        project_dir: "src/#{@project}",
        scripts_dir: "src/#{@project}/#{@scripts_dir}"
      )
    end
  end

  class OctopusDeployConfig
    # The server name of the deployment server
    attr_writer :server

    # The API key of the deployment server
    attr_writer :api_key

    def deploy_app
      config = OctopusDeployAppConfig.new
      yield config
      apps << config
    end

    def apps
      @apps ||= []
    end

    def opts
      raise ArgumentError, 'You must specify a :server to deploy to' if @server.blank?
      raise ArgumentError, 'You must specify at least one application to deploy' if apps.blank?

      Map.new({
        server: @server,
        api_key: @api_key,
        apps: apps.map { |a| a.opts }
      })
    end
  end

  class OctopusDeployAppConfig
    # The name for the build task
    attr_writer :name

    # The project to deploy
    attr_writer :project

    # The type of app to deploy
    attr_writer :type

    # The programming language of the project to deploy
    attr_writer :lang

    def with_metadata(&block)
      @metadata = Albacore::NugetModel::Metadata.new
      block.call @metadata
    end

    def initialize
      @type = :console
      @lang = :cs
    end

    def opts
      raise ArgumentError, 'You must specify a :project to deploy' if @project.blank?
      raise ArgumentError, 'You must specify the :type of project to deploy' if @type.blank?
      raise ArgumentError, "Project :type #{@type} is not supported." unless supported_types.include? @type

      Map.new({
        type: @type,
        name: @name || @project,
        project: @project,
        project_file: CruxRake::Project.get_path(@project, @lang),
        metadata: @metadata
      })
    end

    private

    def supported_types
      [ :console, :service, :website ]
    end
  end
end