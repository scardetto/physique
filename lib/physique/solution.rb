require 'rake'
require 'albacore'
require 'physique/tasks_builder'

module Physique
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

    def fluently_migrate
      @migrator = FluentMigratorConfig.new
      yield @migrator
    end

    alias_method :database, :fluently_migrate

    def octopus_deploy
      @octopus = OctopusDeployConfig.new
      yield @octopus
    end

    def publish_nugets
      @publish_nugets = PublishNugetsConfig.new
      yield @publish_nugets
    end

    def opts
      Map.new({
        file: @file,
        nuget: @nuget && @nuget.opts,
        compile: @compilation && @compilation.opts,
        test: @tests && @tests.opts,
        migrator: @migrator && @migrator.opts,
        octopus: @octopus && @octopus.opts,
        publish_nugets: @publish_nugets && @publish_nugets.opts,
      })
    end
  end

  class Solution
    def initialize(&block)
      config = SolutionConfig.new
      block.call config
      TasksBuilder.build_tasks_for config.opts
    end
  end
end