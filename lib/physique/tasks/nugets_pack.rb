require 'albacore/task_types/nugets_pack'

module Albacore
  module NugetsPack
    # the nuget command
    class Cmd
      def disable_package_analysis
        @parameters << '-NoPackageAnalysis'
      end
    end
  end
end
