require 'active_support/core_ext/object/blank'
require 'physique/project_path_resolver'

module Physique
  class FluentMigratorConfig
    self.extend Albacore::ConfigDSL
    include Albacore::Logging

    # Project name or path
    attr_path :project

    attr_writer :lang,        # Programming language of the db project
                :instance,    # Server instance name
                :name,        # Database name
                :scripts_dir, # Scripts folder to examine to create tasks
                :dialect,     # Dialect to use for generating SQL
                :task_alias   # Alias used to construct rake task names

    def initialize
      @lang = :cs
      @scripts_dir = '_Scripts'
    end

    def opts
      validate_config

      Map.new({
        lang: @lang,
        instance: @instance,
        name: @name,
        scripts_dir: @scripts_dir,
        dialect: @dialect,
        project_file: Physique::ProjectPathResolver.resolve(@project, @lang),
        task_alias: (@task_alias || @name),
      })
    end

    private

    def validate_config
      raise ArgumentError, 'You must specify a database instance' if @instance.blank?
      raise ArgumentError, 'You must specify a database name' if @name.blank?
      raise ArgumentError, 'You must specify the FluentMigrator project' if @project.blank?
      raise ArgumentError, 'You must specify a language' if @lang.blank?
      raise ArgumentError, 'You must specify a scripts_dir' if @scripts_dir.blank?
    end
  end

  class FluentMigratorTasksBuilder < TasksBuilder
    def build_tasks
      dbs = solution.fluent_migrator_dbs
      return if dbs.blank?

      dbs.each do |db|
        expand_project_config db
        task_namespace = db_task_name(db)

        namespace :db do
          namespace task_namespace do
            # First look at the scripts_dir and add a task for every sql file that you find
            defaults = default_tasks(db.name)
            add_script_tasks db, defaults

            # Then add the default minimum required tasks in case the scripts_dir didn't contain them
            add_default_db_tasks db, defaults

            # Add the migrate and rollback tasks
            add_migrator_tasks db

            # Add the tasks to create the db from scratch
            add_create_tasks

            # Add a task to create a new migration in the db project
            add_new_migration_task db
          end
        end

        # Rebuild the databases when running tests
        task :test => "db:#{task_namespace}:rebuild"
      end

      alias_default_tasks
    end

    private

    def expand_project_config(db)
      project = Albacore::Project.new(db.project_file)
      db[:project_namespace] = project.namespace
      db[:project_dir] = project.proj_path_base
      db[:scripts_dir] = "#{project.proj_path_base}/#{db.scripts_dir}"

      build_conf = solution.compile.configuration
      db[:output_path] = project.output_path build_conf
      db[:output_dll] = File.expand_path("#{db.project_dir}/#{project.output_dll(build_conf)}")
    end

    def add_script_tasks(db, defaults)
      FileList["#{db.scripts_dir}/*.sql"].each do |f|
        task_name = File.basename(f, '.*')

        desc get_script_task_description(defaults, task_name, db)
        sqlcmd task_name do |s|
          s.file = f
          s.server_name = db.instance
          s.set_variable 'DATABASE_NAME', db.name
        end
      end
    end

    def get_script_task_description(defaults, task_name, db)
      default_task = defaults[task_name.to_sym]
      default_task ? default_task[:description] : "Executes #{task_name}.sql on #{db.name} in the #{db.scripts_dir} folder."
    end

    def add_default_db_tasks(db, defaults)
      defaults.each do |task_name,task_details|
        unless Rake::Task.task_defined? "db:#{db_task_name(db)}:#{task_name.to_s}"
          desc task_details[:description]
          sqlcmd task_name do |s|
            s.command = task_details[:command]
            s.server_name = db.instance
            s.set_variable 'DATABASE_NAME', db.name
          end
        end
      end
    end

    def default_tasks(database)
      { create: { description: 'Create the database', command: "CREATE DATABASE #{database}" },
        drop: { description: 'Drop the database', command: "DROP DATABASE #{database}"},
        seed: { description: 'Seed the database with test data', command: 'SELECT 1' } } # This is a no-op
    end

    def add_migrator_tasks(db)
      require 'physique/tasks/fluent_migrator'

      # Compile just the database project.
      # This task is registered as a dependency of the migration
      # tasks to ensure the latest code is available.
      build :compile_db => [ :restore ] do |b|
        b.target = [ 'Build' ]
        b.file = db.project_file
        b.prop 'Configuration', solution.compile.configuration
        b.logging = solution.compile.logging
      end

      block = lambda &method(:configure_migration)

      # Migrate up
      desc 'Migrate database to the latest version'
      fluent_migrator :migrate => [ :compile_db ], &block.curry.(db, 'migrate:up')

      # Migrate down
      desc 'Rollback the database to the previous version'
      fluent_migrator :rollback => [ :compile_db ], &block.curry.(db, 'rollback')

      # Try the migration
      desc 'Migrate and then immediately rollback'
      task :try => [ :migrate, :rollback ]
    end

    def configure_migration(db, task, config)
      config.instance = db.instance
      config.database = db.name
      config.task = task
      config.dll = %{"#{db.output_dll}"}
      config.exe = locate_tool(tool_in_output_folder(db) || tool_in_nuget_package)
      config.output_to_file
    end

    def add_create_tasks
      # Setup the database from nothing
      desc 'Create the database and run all migrations'
      task :setup => [ :create, :migrate, :seed ]

      # Drop and recreate the database
      desc 'Drop and recreate the database'
      task :rebuild => [ :drop, :setup ]
    end

    def tool_in_output_folder(db)
      existing_path "#{db.output_path}/Migrate.exe"
    end

    def tool_in_nuget_package
      existing_path "#{solution.nuget.restore_location}/FluentMigrator.*/tools/Migrate.exe"
    end

    def existing_path(path)
      return path if FileList[path].any? { |p| File.exists? p }
      nil
    end

    def db_task_name(db)
      db.task_alias.downcase
    end

    def add_new_migration_task(db)
      desc 'Create a new migration file with the specified name'
      task :new_migration, :name, :description do |t, args|
        name, description = args[:name], args[:description]

        unless name
          abort [
            %Q{Usage: rake "#{t.name}[name[,description]]"},
            desc,
          ].join "\n\n"
        end

        # Save the new migration file
        version = migration_version
        migration_file_name = "#{version}_#{name}.cs"
        migration_content = migration_template(version, name, description, db.project_namespace)
        save_file migration_content, "#{db.project_dir}/Migrations/#{migration_file_name}"

        # Add the new migration file to the project
        Albacore::Project.new(db.project_file).tap do |p|
          p.add_compile_node :Migrations, migration_file_name
          p.save
        end
      end
    end

    def migration_version
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end

    def migration_template(version, name, description, project_namespace)
      description = ", \"#{description}\"" unless description.nil?
      return <<TEMPLATE
using FluentMigrator;

namespace #{project_namespace}.Migrations
{
    [Migration(#{version}#{description})]
    public class #{name} : Migration
    {
        public override void Up()
        {
            // Add migration code here
        }

        public override void Down()
        {
            // Add migration rollback code here
        }
    }
}
TEMPLATE
    end

    def save_file(content, file_path)
      raise "#{file_path} already exists, cancelling" if File.exists? file_path
      File.open(file_path, 'w') { |f| f.write(content) }
    end

    def alias_default_tasks
      Rake.application.tasks
        .select {|t| should_alias_db_task?(t)}
        .group_by {|t| db_command(t) }
        .each do |command,tasks|
          desc global_task_description(command,tasks)
          task "db:#{command}", tasks[0].arg_names => tasks.map {|t| t.name }
        end
    end

    def db_command(task)
      task.name.split(':').last.to_sym
    end

    def should_alias_db_task?(task)
      task.name.starts_with?('db') &&
        (only_one_db_configured? ||
          GLOBAL_TASKS.has_key?(db_command(task)))
    end

    def global_task_description(command, tasks)
      return GLOBAL_TASKS[command] unless only_one_db_configured?

      # Blank out the comment to hide the task in the list by default
      description = tasks[0].comment
      tasks[0].clear_comments
      description
    end

    def only_one_db_configured?
      solution.fluent_migrator_dbs.length == 1
    end

    GLOBAL_TASKS = {
        create: 'Create all databases',
        drop: 'Drop all databases',
        seed: 'Seed all databases with test data',
        setup: 'Build all databases and migrate them to the latest version',
        rebuild: 'Drop and recreate all databases',
        migrate: 'Migrates all databases to the latest version' }
  end
end