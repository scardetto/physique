require 'active_support/core_ext/string'
require 'albacore'
require 'albacore/cmd_config'
require 'physique/tool_locator'

module Physique
  module SqlCmd
    class Cmd
      include Albacore::CrossPlatformCmd

      attr_reader :parameters

      def initialize(opts)
        @executable = opts[:exe]
        set_parameters opts
      end

      def execute
        sh "#{@executable} #{@parameters.join(' ')}"
      end

      private

      def set_parameters(opts)
        @parameters = @parameters || []
        @parameters << "-S #{opts[:server_name]}"
        @parameters << "-d #{opts[:database_name]}" unless opts.blank? :database_name
        @parameters << "-i #{opts[:file]}" if opts[:source] == :file
        @parameters << %{-Q "#{opts[:command]}"} if opts[:source] == :command
        @parameters << '-b' unless opts[:continue_on_error]

        opts[:variables].each do |k, v|
          @parameters << "-v #{k}=#{v}"
        end
      end
    end

    class Config
      include Albacore::CmdConfig
      include Physique::ToolLocator
      self.extend Albacore::ConfigDSL

      # The database server
      attr_path :server_name

      # The database name
      attr_writer :database_name

      # The sql script to execute
      attr_path :file

      # The sql command to execute
      attr_writer :command

      def initialize
        @variables = Hash.new
        @continue_on_error = false

        @exe = which('sqlcmd') ||
            locate_tool('C:/Program Files/Microsoft SQL Server/**/Tools/Binn/SQLCMD.EXE')
      end

      def set_variable(k, v)
        @variables[k] = v
      end

      def continue_on_error
        @continue_on_error = true
      end

      def opts
        raise ArgumentError, 'You must specify a server name' if @server_name.blank?
        raise ArgumentError, 'You must specify a command or a file to execute' unless can_execute?

        Map.new({
          exe: @exe,
          server_name: @server_name,
          database_name: @database_name,
          file: @file,
          command: @command,
          source: execute_source,
          continue_on_error: @continue_on_error,
          variables: @variables
        })
      end

      private

      def can_execute?
        !(@file.blank? && @command.blank?)
      end

      def execute_source
        # Command takes precedence over a file
        return :command unless @command.blank?
        :file
      end
    end

    class Task
      def initialize(opts)
        @cmd = Physique::SqlCmd::Cmd.new opts
      end

      def execute
        @cmd.execute
      end
    end
  end
end