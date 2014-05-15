require 'cruxrake/tool_locator'

module CruxRake
  module TestsTasksBuilder
    include CruxRake::ToolLocator

    def add_test_tasks
      configuration = @solution.compile.configuration
      package_dir = @solution.nuget.restore_location

      task = test_runner_task :test => [ :compile, 'db:rebuild' ] do |tests|
        tests.files = FileList["**/*.Tests/bin/#{configuration}/*.Tests.dll"]
        tests.exe = locate_tool("#{package_dir}/NUnit.Runners.*/tools/nunit-console.exe")
      end
      task.add_description 'Run unit tests'
    end
  end
end