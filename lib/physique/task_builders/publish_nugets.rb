require 'physique/config'
require 'forwardable'

module Physique
  class PublishNugetsConfig < MetadataConfig
    extend Forwardable

    attr_writer :project_files, # Project files to include
                :exclude,       # Project files to exclude
                :local_path     # Path to publish locally

    def initialize
      super
      @feeds = []
      @alias_tasks = true
    end

    # Do not alias the tasks without the 'nuget' prefix.
    def no_alias_tasks
      @alias_tasks = false
    end

    def_delegators :default_feed, :feed_url=, :symbols_feed_url=, :api_key=

    def opts
      Map.new(
        project_files: FileList[project_files_or_default].exclude(exclude_or_default),
        metadata: @metadata,
        local_path: @local_path,
        feed_url: @feed_url,
        gen_symbols: @gen_symbols,
        symbols_feed_url: @symbols_feed_url,
        api_key: @api_key,
        alias_tasks: @alias_tasks,
        feeds: @feeds.map { |f| f.opts }
      ).apply(
        local_path: 'C:/Nuget.Local'
      )
    end

    def project_files_or_default
      @project_files || 'src/**/*.{csproj,fsproj,nuspec}'
    end

    def exclude_or_default
      @exclude || /Tests/
    end

    private

    def default_feed
      @default_feed || create_default_feed
    end

    def create_default_feed
      PublishNugetsFeedConfig.new.tap do |feed|
        feed.name = 'default'
        @default_feed = feed
        @feeds << feed
      end
    end
  end

  class PublishNugetsFeedConfig
    attr_writer :name,     # Name of the nuget feed
                :feed_url, # Nuget feed to publish packages
                :api_key   # Nuget API key

    # Nuget feed to publish symbol packages
    def symbols_feed_url=(value)
      @gen_symbols = true
      @symbols_feed_url = value
    end

    def opts
      raise ArgumentError, 'You must specify a name for all nuget feeds' if @name.blank?
      raise ArgumentError, "You must specify a feed_url for feed #{name}" if @feed_url.blank?

      Map.new(
        name: @name,
        feed_url: @feed_url,
        gen_symbols: @gen_symbols,
        symbols_feed_url: @symbols_feed_url,
        api_key: @api_key
      )
    end
  end

  class PublishNugetsTasksBuilder < TasksBuilder
    def build_tasks
      @options = solution.publish_nugets
      return if @options.nil?

      namespace :nuget do
        add_package_nugets_task
        add_publish_nugets_task
        add_publish_nugets_local_task
      end

      if @options.alias_tasks
        add_task_aliases
      end
    end

    private

    def add_package_nugets_task
      desc 'Package all nugets'
      nugets_pack :package => [ :versionizer, :test ] do |p|
        ensure_output_location solution.nuget.build_location

        p.configuration = solution.compile.configuration
        p.out           = solution.nuget.build_location
        p.exe           = solution.nuget.exe
        p.files         = @options.project_files
        p.gen_symbols   if @options.gen_symbols
        p.with_metadata do |m|
          @options.metadata.set_fields.each do |attr|
            eval "m.#{attr}= @options.metadata.#{attr}"
          end
        end
      end
    end

    def add_publish_nugets_task
      desc 'Publish nuget packages to feed'
      task :publish => [ 'nuget:package' ] do
        raise ArgumentError, 'You must specify an :api_key to connect to the server' if @options.api_key.blank?

        nuget_project_names.each do |p|
          sh nuget_publish_command(p, 'nupkg', @options.feed_url)

          if @options.gen_symbols
            sh nuget_publish_command(p, 'symbols.nupkg', @options.symbols_feed_url)
          end
        end
      end
    end

    def nuget_publish_command(name, extension, feed)
      "#{solution.nuget.exe} push #{solution.nuget.build_location}/#{name}.#{@options.metadata.version}.#{extension} #{@options.api_key} -Source #{feed}"
    end

    def add_publish_nugets_local_task
      local_path = @options.local_path

      namespace :publish do
        desc 'Copy nuget packages to local path'
        task :local => [ 'nuget:package' ] do
          ensure_output_location local_path
          FileUtils.cp FileList["#{solution.nuget.build_location}/*"], local_path
        end
      end
    end

    def nuget_project_names
      Set.new(@options.project_files.map { |f| Albacore::Project.new f }.map { |p| p.name })
    end

    def add_task_aliases
      desc 'Package all nugets'
      task :package => [ 'nuget:package' ]

      desc 'Publish nuget packages to feed'
      task :publish => [ 'nuget:publish' ]
    end
  end
end