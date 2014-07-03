require 'albacore'
require 'albacore/nuget_model'
require 'cruxrake/config'

module CruxRake
  class OctopusDeployConfig
    attr_writer :server,  # The server name of the deployment server
                :api_key  # The API key of the deployment server

    def initialize
      @apps = []
      @alias_tasks = true
    end

    # Do not alias the tasks without the 'octo' prefix.
    def no_alias_tasks
      @alias_tasks = false
    end

    def deploy_app
      config = OctopusDeployAppConfig.new
      yield config
      @apps << config
    end

    def opts
      raise ArgumentError, 'You must specify a server to deploy to' if @server.blank?
      raise ArgumentError, 'You must specify at least one application to deploy' if @apps.blank?

      Map.new({
        server: @server,
        api_key: @api_key,
        alias_tasks: @alias_tasks,
        apps: @apps.map { |a| a.opts }
      })
    end
  end

  class OctopusDeployAppConfig < MetadataConfig
    attr_writer :name,    # The name for the build task
                :project, # The project to deploy
                :type,    # The type of app to deploy
                :lang     # The programming language of the project to deploy

    def initialize
      super
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

  class OctopusTasksBuilder < TasksBuilder
    def build_tasks
      @options = solution.octopus
      return if @options.nil?
      return if @options.apps.blank?

      add_octopus_package_tasks
      add_octopus_publish_tasks

      if @options.alias_tasks
        add_task_aliases
      end
    end

    private

    def add_octopus_package_tasks
      @options.apps.each do |a|
        namespace :octo do
          namespace :package do
            task = octopus_pack_task a.name => [:versionizer, :test] do |o|
              ensure_output_location solution.nuget.build_location

              o.project_file = a.project_file
              o.type = a.type
              o.configuration = solution.compile.configuration
              o.exe = solution.nuget.exe
              o.out = solution.nuget.build_location
              o.metadata = a.metadata
            end
            task.add_description "Create the Octopus deployment package for #{a.project}"
          end
        end

        task = Rake::Task.define_task :package => all_octopus_package_tasks
        task.add_description 'Package all applications'
      end
    end

    def all_octopus_package_tasks
      @options.apps.map { |a| "package:#{a.name}" }
    end

    def add_octopus_publish_tasks
      nuget = solution.nuget

      namespace :octo do
        task = Rake::Task.define_task :publish => [ 'octo:package' ] do
          raise ArgumentError, 'You must specify an :api_key to connect to the server' if @options.api_key.blank?

          @options.apps.each do |a|
            sh "#{nuget.exe} push #{nuget.build_location}/#{a.project}.#{a.metadata.version}.nupkg -ApiKey #{@options.api_key} -Source #{@options.server}"
          end
        end
        task.add_description 'Publish apps to Octopus Server'
      end
    end

    def add_task_aliases
      task = Rake::Task.define_task :package => [ 'octo:package' ]
      task.add_description 'Package all applications'

      task = Rake::Task.define_task :publish => [ 'octo:publish' ]
      task.add_description 'Publish apps to Octopus Server'
    end
  end
end