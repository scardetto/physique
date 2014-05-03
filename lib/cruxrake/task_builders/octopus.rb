require 'active_support/core_ext/array'
require 'albacore/nuget_model'

module CruxRake
  module OctopusTasksBuilder
    def add_octopus_tasks
      options = @solution.octopus
      return if options.apps.blank?

      options.apps.each do |a|
        namespace :package do
          task = octopus_pack_task a.name => [ :versionizer, :compile ] do |o|
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

    private

    def all_package_tasks(options)
      options.apps.map { |a| "package:#{a.name}" }
    end
  end
end

