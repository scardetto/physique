require 'map'
require 'albacore'

module Physique
  module ToolLocator
    include Albacore::Logging

    # Allows you to locate a tool on disk given a file specification. For example...
    #
    #   locate_tool 'C:/Program Files/Microsoft SQL Server/**/Tools/Binn/SQLCMD.EXE'
    #
    # The tool sorts any matching executables in descending order to that the most recent version is returned. To
    # change this behavior call the method with the reverse option.
    #
    #   locate_tool 'C:/path/to/**/tool.exe', find_latest: false
    #
    # Throws a ToolNotFoundError if no tool could be found.
    def locate_tool(paths, options = {})
      # FileList only correctly handles forward-slashes, even on Windows
      paths = paths.gsub('\\', '/')

      info { "Extracting paths from the following pattern #{paths}" }
      paths = FileList[paths] unless paths.respond_to?(:each)

      info { "Attempting to locate tool in the following paths #{paths}" }
      opts = Map.options(options)
      opts = opts.apply :find_latest => true
      paths = paths.collect { |p| which(p) }.compact.sort
      paths = paths.reverse if opts[:find_latest]
      tool = paths.first

      raise ToolNotFoundError, "Could not find tool in the following paths: \n #{paths}" if tool.nil?
      tool
    end

    def which(exe)
      Albacore::CrossPlatformCmd.which(exe) ? exe : nil;
    end

    class ToolNotFoundError < Exception; end
  end
end