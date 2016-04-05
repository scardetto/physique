require 'albacore/logging'
require 'physique/tasks/nugets_pack'

module Physique
  module OctopusPack
    class Config
      attr_writer :project_file
      attr_writer :type
      attr_writer :configuration
      attr_writer :exe
      attr_writer :out
      attr_writer :original_path
      attr_writer :metadata

      def opts
        raise ArgumentError, 'You must specify a project file' if @project_file.blank?
        raise ArgumentError, 'You must specify a version' if @metadata.version.blank?
        raise ArgumentError, 'You must specify the NuGet executable' if @exe.blank?
        raise ArgumentError, 'You must specify an output folder' if @out.blank?

        Map.new({
          project_file: @project_file,
          type: @type,
          configuration: @configuration,
          exe: @exe,
          out: @out,
          original_path: @original_path,
          metadata: @metadata,
        }).apply({
          type: :console,
          configuration: 'Release',
          original_path: FileUtils.pwd,
          verify_files: true,
        })
      end
    end

    class Task
      include Albacore::Logging

      def initialize(opts)
        @opts = opts
        @project = Albacore::Project.new opts.project_file

        opts.metadata.id = @project.name if @project.name
        @package = Albacore::NugetModel::Package.new opts.metadata
      end

      def execute
        if @opts.type == :website
          add_content_files
          add_binary_files target: 'bin'
        else
          add_content_files
          add_binary_files
        end

        nuspec_path = write_nuspec!
        create_nuget! @project.proj_path_base, nuspec_path
      ensure
        cleanup_nuspec nuspec_path
      end

      private

      def write_nuspec!
        raise ArgumentError, "no nuspec metadata id, project at path: #{@project.proj_path_base}, nuspec: #{@package.inspect}" unless @package.metadata.id

        path = File.join(@project.proj_path_base, @package.metadata.id + '.nuspec')
        File.write(path, @package.to_xml)
        path
      end

      def create_nuget!(cwd, nuspec_file)
        # create the command
        exe = path_to(@opts.exe, cwd)
        out = path_to(@opts.out, cwd)
        nuspec = path_to(nuspec_file, cwd)
        cmd = Albacore::NugetsPack::Cmd.new exe,
                                            work_dir: cwd,
                                            out: out

        # Octopus packages don't conform to NuGet standards so
        # disable package analysis to prevent unnecessary warnings.
        cmd.disable_package_analysis

        # run the command for the file
        pkg, _ = cmd.execute nuspec

        publish_artifact nuspec, pkg
      end

      def cleanup_nuspec nuspec
        return if nuspec.nil? or not File.exists? nuspec
        return if @opts.get :leave_nuspec, false
        File.delete nuspec
      end

      def path_to(relative_file_path, cwd)
        File.expand_path(File.join(@opts.get(:original_path), relative_file_path), cwd)
      end

      def publish_artifact(nuspec, nuget)
        Albacore.publish :artifact, OpenStruct.new(
          nuspec: nuspec,
          nupkg: nuget,
          location: nuget
        )
      end

      def add_content_files
        @project.
          included_files.
          keep_if { |f| f.item_name == 'content' && f.item_name != 'packages.config' }.
          each { |f| @package.add_file URI.unescape(f.include), URI.unescape(f.include) }
      end

      def add_binary_files(options = {})
        target = options[:target] || ''

        output_path = get_output_path
        Dir.new(get_absolute_output_path).entries.
          keep_if { |f| f =~ /^.*\.(dll|exe|pdb|config)$/i}.
          each { |f| @package.add_file bin_target(output_path, f), bin_target(target, f) }
      end

      def bin_target(target, file_name)
        return file_name if target.blank?
        File.join(target, file_name)
      end

      def get_absolute_output_path
        File.expand_path get_output_path, @project.proj_path_base
      end

      def get_output_path
        Albacore::NugetModel::Package.get_output_path(@project, Map.new(configuration: @opts.configuration))
      end
    end
  end
end
