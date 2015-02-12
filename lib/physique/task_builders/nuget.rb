module Physique
  class NugetConfig
    self.extend Albacore::ConfigDSL

    attr_path :exe,               # Path to nuget executable
              :restore_location,  # Path where nuget packages will be downloaded
              :build_location     # Path where nuget packages will be built

    # Disable metadata analysis (sets -NoPackageAnalysis flag)
    def disable_package_analysis
      @disable_package_analysis = true
    end

    def initialize
      @exe = 'src/.nuget/NuGet.exe'
      @restore_location = 'src/packages'
      @build_location = 'build/packages'
    end

    def opts
      Map.new({
        exe: @exe,
        restore_location: @restore_location,
        build_location: @build_location,
        disable_package_analysis: !!@disable_package_analysis
      })
    end
  end

  class NugetTasksBuilder < TasksBuilder
    def build_tasks
      add_restore_task
    end

    private

    def add_restore_task
      desc 'Restores all nugets as per the packages.config files'
      nugets_restore :restore do |r|
        r.out = solution.nuget.restore_location
        r.exe = solution.nuget.exe
      end
    end
  end
end