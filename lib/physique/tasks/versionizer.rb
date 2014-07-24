require 'xsemver'
require 'albacore/logging'

module Physique
  module Tasks
    # Versionizer does versioning ITS OWN WAY!
    #
    # Defines ENV vars:
    #  * BUILD_VERSION
    #  * NUGET_VERSION
    #  * FORMAL_VERSION
    #
    # Publishes symbol :build_version
    module Versionizer
      # adds a new task with the given symbol to the Rake/Albacore application
      # You can use this like any other albacore method, such as build,
      # in order to give it parameters or dependencies, but there is no
      # configuration object that you can configure. Copy-n-paste this
      # code if you want something of your own.
      #
      def self.new(*sym)
        version = gitflow_version(XSemVer::SemVer.find)
        version_data = define_versions(version)

        Albacore.subscribe :build_version do |data|
          ENV['BUILD_VERSION']  = data.build_version
          ENV['NUGET_VERSION']  = data.nuget_version
          ENV['FORMAL_VERSION'] = data.formal_version
          ENV['LONG_VERSION']   = data.long_version
        end

        Albacore.define_task(*sym) do
          Albacore.publish :build_version, OpenStruct.new(version_data)
        end

        Albacore.define_task :version do
          puts version_data.inspect
        end
      end

      def self.define_versions(semver)
        build = build_number

        {
          # just a monotonic inc
          :semver         => semver,
          :build_number   => build,
          :current_branch => current_branch,

          # purely M.m.p format
          :formal_version => "#{semver.format('%M.%m.%p')}",

          # four-numbers version, useful if you're dealing with COM/Windows
          :long_version   => "#{semver.format('%M.%m.%p')}.#{build}",

          # extensible number w/ git hash
          :build_version  => "#{semver.format('%M.%m.%p%s')}.#{last_commit[0]}",

          # nuget (not full semver 2.0.0-rc.1 support) see http://nuget.codeplex.com/workitem/1796
          :nuget_version  => semver.format('%M.%m.%p%s')
        }
      end

      # load the commit data
      # returns: [short-commit :: String]
      #
      def self.last_commit
        begin
          `git rev-parse --short HEAD`.chomp[0,6]
        rescue
          (ENV['BUILD_VCS_NUMBER'] || '000000')[0,6]
        end
      end

      # Determine the current branch
      # returns: branch name
      #
      def self.current_branch
        begin
          `git rev-parse --abbrev-ref HEAD`.chomp
        rescue
          'master'
        end
      end

      def self.gitflow_version(version)
        return unless ENV.include?('BUILD_NUMBER')
        version.special = gitflow_special
        version
      end

      def self.build_number
        ENV['BUILD_NUMBER'] || '0'
      end

      def self.gitflow_special
        prefix = special_prefix
        return version.special if prefix == 'master'

        "#{prefix}#{build_number}"
      end

      def self.special_prefix
        # TODO: There is a better way to do this.
        branch_name = current_branch
        return 'release' if branch_name.start_with? 'release/'
        return 'hotfix' if branch_name.start_with? 'hotfix/'
        return 'feature' if branch_name.start_with? 'feature/'
        branch_name
      end
    end
  end
end