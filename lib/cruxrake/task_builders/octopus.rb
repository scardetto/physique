require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
require 'albacore'
require 'albacore/nuget_model'

module CruxRake
  module OctopusTasksBuilder
    def add_octopus_tasks
      options = @solution.octopus
      return if options.apps.blank?

      add_package_tasks(options)
      add_deploy_tasks(options)
    end

    private

    def add_package_tasks(options)
      options.apps.each do |a|
        namespace :package do
          task = octopus_pack_task a.name => [:versionizer, :test] do |o|
            ensure_output_location

            o.project_file = a.project_file
            o.type = a.type
            o.version = ENV['NUGET_VERSION'] # from versionizer task
            o.configuration = @solution.compile.configuration
            o.exe = @solution.nuget.exe
            o.out = @solution.nuget.build_location
          end
          task.add_description "Create the Octopus deployment package for #{a.project}"
        end
      end

      task = Rake::Task.define_task :package => all_package_tasks(options)
      task.add_description 'Package all applications'
    end

    def all_package_tasks(options)
      options.apps.map { |a| "package:#{a.name}" }
    end

    def ensure_output_location
      # Ensure output directory exists
      FileUtils.mkdir_p @solution.nuget.build_location
    end

    def add_deploy_tasks(options)
      nuget = @solution.nuget

      task = Rake::Task.define_task :publish => [ :package ] do
        raise ArgumentError, 'You must specify an :api_key to connect to the server' if options.api_key.blank?

        options.apps.each do |a|
          sh "#{nuget.exe} push #{nuget.build_location}/#{a.project}.#{ENV['NUGET_VERSION']}.nupkg -ApiKey #{options.api_key} -Source #{options.server}"
        end
      end
      task.add_description 'Publish apps to Octopus Server'
    end
  end
end

