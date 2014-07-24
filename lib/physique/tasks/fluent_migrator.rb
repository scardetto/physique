require 'active_support/core_ext/string'
require 'map'

module Physique
  module FluentMigrator
    class Cmd
      include Albacore::CrossPlatformCmd

      attr_reader :parameters

      def initialize(opts)
        @work_dir = opts[:work_dir]
        @executable = opts[:exe]
        set_parameters opts
      end

      def execute
        sh "#{@executable} #{@parameters.join(' ')}"
      end

      private

      def set_parameters(opts)
        @parameters = @parameters || []
        @parameters << "--target #{opts.dll}"
        @parameters << "--provider #{opts.dialect}"
        @parameters << %Q{--connectionString "#{opts.connection_string}"}
        @parameters << "--task #{opts.task}"
        @parameters << "--namespace #{opts.namespace}" unless opts.namespace.blank?
        @parameters << "--nested #{opts.nested}" unless opts.namespace.blank? # Modifies the namespace option
        @parameters << "--output --outputFileName #{opts.output_file}" unless opts.output_file.blank?
        @parameters << '--preview true' if opts.preview
        @parameters << "--steps #{opts.steps}" if opts.task =~ /rollback/
        @parameters << "--version #{opts.version}" if opts.task =~ /^migrate($|:up)|^rollback:toversion$/
        @parameters << '--transaction-per-session' if opts.tps
      end
    end

    class Config
      include Albacore::CmdConfig
      include Physique::ToolLocator
      self.extend Albacore::ConfigDSL

      # SQL Server instance
      attr_path :instance

      # SQL Server database
      attr_writer :database

      # SQL dialect
      attr_writer :dialect

      # Dll containing the migrations
      attr_path :dll

      # Namespace of migration to run
      def namespace=(val)
        @namespace = val
        @nested = true
      end

      def shallow
        @nested = false
      end

      def deep
        @nested = true
      end

      # Migration task
      attr_writer :task

      # Version number to migrate to
      attr_writer :version

      # Number of steps to rollback
      attr_writer :steps

      # Verbosity
      attr_writer :verbose

      # Timeout
      attr_writer :timeout

      # Output file
      attr_path :output_file

      def output_to_file
        # Set a default output file
        @output_file = "#{@database}-output.sql"
      end

      def transaction_per_session
        @tps = true
      end

      def preview
        @preview = true
      end

      # Path Migrator executable
      attr_path :exe

      # Bin folder to look find the Migrate tool if :exe is not set
      attr_path :bin_dir

      def opts
        raise ArgumentError, 'You must specify a server name' if @instance.blank?
        raise ArgumentError, 'You must specify a database name' if @database.blank?
        raise ArgumentError, 'You must specify the path to the migrator executable' if @exe.blank?
        raise ArgumentError, 'You must specify a migration dll' if @dll.blank?
        raise ArgumentError, 'You must specify a valid task' unless valid_tasks.include? @task

        Map.new({
          connection_string: connection_string,
          dialect: @dialect,
          dll: @dll,
          namespace: @namespace,
          nested: @nested,
          task: @task,
          version: @version,
          steps: @steps,
          verbose: @verbose,
          output_file: @output_file,
          exe: @exe,
          tps: @tps,
          preview: @preview,
          timeout: @timeout,
        }).apply(
          dialect: 'SqlServer2008',
          verbose: true,
          version: 0,
          steps: 1,
          timeout: 30 # seconds
        )
      end

      private

      def connection_string
        "Data Source=#{@instance};Initial Catalog=#{@database};Integrated Security=True;"
      end

      def valid_tasks
         %w{migrate:up migrate migrate:down rollback rollback:toversion rollback:all validateversionorder listmigrations}
      end
    end

    class Task
      def initialize(opts)
        @cmd = Physique::FluentMigrator::Cmd.new opts
      end

      def execute
        @cmd.execute
      end
    end
  end
end