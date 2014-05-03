module CruxRake
  module NugetTasksBuilder
    def add_nuget_tasks
      define_nuget_restore
    end

    def define_nuget_restore
      options = @solution.nuget

      task = nugets_restore_task :restore do |r|
        r.out = options.restore_location
        r.exe = options.exe
      end
      task.add_description 'Restores all nugets as per the packages.config files'
    end
  end
end