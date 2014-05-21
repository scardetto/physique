require 'rake'
require 'albacore'
require 'cruxrake/config'
require 'cruxrake/dsl'
require 'cruxrake/tasks_builders'

module CruxRake
  class Solution
    include Albacore::DSL
    include Albacore::Logging
    include CruxRake::BuildTasksBuilder
    include CruxRake::NugetTasksBuilder
    include CruxRake::DatabaseTasksBuilder
    include CruxRake::TestsTasksBuilder
    include CruxRake::OctopusTasksBuilder

    def initialize(&block)
      config = SolutionConfig.new
      block.call config
      @solution = config.opts

      add_build_tasks
      add_nuget_tasks
      add_database_tasks
      add_test_tasks
      add_octopus_tasks
      add_default_tasks
    end

    private

    def add_default_tasks
      Rake::Task.define_task :default => [ :test ]
      Rake::Task.define_task :ci => [ :versionizer, :test ]
    end

    def namespace(name, &block)
      name = name.to_s if name.kind_of?(Symbol)
      name = name.to_str if name.respond_to?(:to_str)
      unless name.kind_of?(String) || name.nil?
        raise ArgumentError, 'Expected a String or Symbol for a namespace name'
      end
      Rake.application.in_namespace(name, &block)
    end
  end
end