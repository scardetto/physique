require 'active_support/core_ext/object/blank'

module Physique
  class TestConfig
    self.extend Albacore::ConfigDSL

    # Path to test runner executable
    attr_path :exe

    # Path to test runner executable
    attr_writer :files

    # The test runner to use
    attr_writer :runner

    # Additional parameters to pass to the test runner
    attr_writer :parameters

    def opts
      Map.new({
        exe: @exe,
        runner: @runner,
        files: @files,
        parameters: @parameters
      }).apply({
        runner: :nunit
      })
    end
  end

  class TestsTasksBuilder < TasksBuilder
    def build_tasks
      add_test_tasks
    end

    def add_test_tasks
      options = solution.test
      defaults = default_runner_config options
      files = options.files || defaults[:files]

      desc 'Run unit tests'

      if defaults && !files.blank?
        test_runner :test => :compile do |tests|
          tests.files = files
          tests.exe = options.exe || locate_tool(defaults[:exe])

          defaults[:parameters].each do |p|
            tests.parameters.add(p)
          end
        end
      else
        task :test => :compile do
          puts 'No test assemblies were detected'
        end
      end
    end

    private

    def default_runner_config(options)
      configuration = solution.compile.configuration
      package_dir = solution.nuget.restore_location

      defaults = {
        nunit: {
            files: FileList["**/*.Tests/bin/#{configuration}/*.Tests.dll"],
            exe: "#{package_dir}/NUnit.Runners*/tools/nunit-console.exe",
            parameters: %w(/labels /trace=Verbose)},
        nspec: {
            files: FileList["**/*.Specs/bin/#{configuration}/*.Specs.dll"],
            exe: "#{package_dir}/nspec*/tools/NSpecRunner.exe",
            parameters: []}}

      defaults[options.runner]
    end
  end
end
