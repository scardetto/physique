module Physique
  class TestConfig
    self.extend Albacore::ConfigDSL

    # Path to test runner executable
    attr_path :exe

    # Path to test runner executable
    attr_writer :files

    def opts
      Map.new({
        exe: @exe,
        files: @files
      })
    end
  end

  class TestsTasksBuilder < TasksBuilder
    def build_tasks
      add_test_tasks
    end

    def add_test_tasks
      configuration = solution.compile.configuration
      package_dir = solution.nuget.restore_location

      desc 'Run unit tests'
      test_runner :test => test_dependencies do |tests|
        tests.files = FileList["**/*.Tests/bin/#{configuration}/*.Tests.dll"]
        tests.exe = locate_tool("#{package_dir}/NUnit.Runners.*/tools/nunit-console.exe")
        tests.parameters.add('/labels')
        tests.parameters.add('/trace=Verbose')
      end
    end

    def test_dependencies
      dependencies = [ :compile ]
      dependencies << 'db:rebuild' unless solution.migrator.nil?
      dependencies
    end
  end
end