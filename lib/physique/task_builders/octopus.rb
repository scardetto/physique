require 'albacore'
require 'albacore/nuget_model'
require 'physique/config'

module Physique
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

      project_file_path = Physique::Project.get_path(@project, @lang)
      _, project_file = File.split project_file_path
      project_name = File.basename(project_file, '.*')

      Map.new({
        type: @type,
        name: @name || @project,
        project: project_name,
        project_file: project_file_path,
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
            task = octopus_pack a.name => [:versionizer, :test] do |o|
              ensure_output_location solution.nuget.build_location

              o.project_file = a.project_file
              o.type = a.type
              o.configuration = solution.compile.configuration
              o.exe = solution.nuget.exe
              o.out = solution.nuget.build_location
              o.metadata = a.metadata
            end
            task.add_description "Package #{a.project} for Octopus deployment"
          end

          task = Rake::Task.define_task :package => all_octopus_app_tasks('package')
          task.add_description 'Package all applications'
        end
      end
    end

    def add_octopus_publish_tasks
      nuget = solution.nuget

      @options.apps.each do |a|
        namespace :octo do
          namespace :publish do
            task = Rake::Task.define_task a.name => [ "package:#{a.name}" ] do
              package_location = Albacore::Paths.normalise_slashes "#{nuget.build_location}/#{a.project}.#{a.metadata.version}.nupkg"
              sh "#{nuget.exe} push #{package_location} -ApiKey #{@options.api_key} -Source #{@options.server}"
            end
            task.add_description "Publish #{a.project} app to Octopus Server"
          end

          task = Rake::Task.define_task :publish => all_octopus_app_tasks('publish')
          task.add_description 'Publish all apps to Octopus Server'
        end
      end
    end

    def all_octopus_app_tasks(task)
      # It is assumed that this is called within the octo namespace
      @options.apps.map { |a| "#{task}:#{a.name}" }
    end

    def add_task_aliases
      task = Rake::Task.define_task :package => [ 'octo:package' ]
      task.add_description 'Package all applications'

      task = Rake::Task.define_task :publish => [ 'octo:publish' ]
      task.add_description 'Publish apps to Octopus Server'
    end
  end
end