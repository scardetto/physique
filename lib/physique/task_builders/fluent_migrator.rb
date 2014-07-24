require 'physique/project'

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
                :dialect      # Dialect to use for generating SQL

    def initialize
      @lang = :cs
      @scripts_dir = '_Scripts'
    end

    def opts
      Map.new({
        exe: @exe,
        instance: @instance,
        name: @name,
        project: @project,
        project_file: Physique::Project.get_path(@project, @lang),
        lang: @lang,
      }).apply(
        lang: :cs,
        project_dir: "src/#{@project}",
        scripts_dir: "src/#{@project}/#{@scripts_dir}"
      )
    end
  end

  class FluentMigratorTasksBuilder < TasksBuilder
    def build_tasks
      @options = solution.migrator
      return if @options.nil?

      add_script_tasks
      add_default_db_tasks
      add_migrator_tasks
      add_workflow_tasks
      add_new_migration_task
    end

    private

    def add_script_tasks
      FileList["#{@options.scripts_dir}/*.sql"].each do |f|
        namespace :db do
          task_name = File.basename(f, '.*')
          task = sqlcmd_task task_name do |s|
            s.file = f
            s.server_name = @options.instance
            s.set_variable 'DATABASE_NAME', @options.name
          end
          task.add_description get_script_task_description(task_name, @options.scripts_dir)
        end
      end
    end

    def add_default_db_tasks
      default_tasks(@options.name).each do |task_name,sql|
        unless Rake::Task.task_defined? "db:#{task_name.to_s}"
          namespace :db do
            task = sqlcmd_task task_name do |s|
              s.command = sql
              s.server_name = @options.instance
              s.set_variable 'DATABASE_NAME', @options.name
            end
            task.add_description get_script_task_description(task_name, @options.scripts_dir)
          end
        end
      end
    end

    def default_tasks(database)
      { create: "CREATE DATABASE #{database}",
        drop: "DROP DATABASE #{database}",
        seed: 'SELECT 1' } # This is a no-op
    end

    def get_script_task_description(task, dir)
      well_known_scripts[task.to_sym] || "Executes #{task}.sql in the #{dir} folder."
    end

    # TODO: Refactor this to combine this with default_tasks
    def well_known_scripts
      { create: 'Creates the database',
        drop: 'Drops the database',
        seed: 'Seeds the database with test data' }
    end

    def add_migrator_tasks
      require 'physique/tasks/fluent_migrator'

      namespace :db do
        build_task :compile_db do |b|
          b.target = [ 'Build' ]
          b.file = solution.migrator.project_file
          b.prop 'Configuration', solution.compile.configuration
          b.logging = solution.compile.logging
        end

        block = lambda &method(:configure_migration)

        # Migrate up
        task = fluent_migrator_task :migrate => [ :compile_db ], &block.curry.('migrate:up')
        task.add_description 'Migrate database to the latest version'

        # Migrate down
        task = fluent_migrator_task :rollback => [ :compile_db ], &block.curry.('rollback')
        task.add_description 'Rollback the database to the previous version'
      end
    end

    def configure_migration(task, config)
      config.instance = solution.migrator.instance
      config.database = solution.migrator.name
      config.task = task
      config.dll = migration_dll
      config.exe = locate_tool(tool_in_output_folder || tool_in_nuget_package)
      config.output_to_file
    end

    def add_workflow_tasks
      namespace :db do
        # Try the migration
        task = Rake::Task.define_task :try => [ :migrate, :rollback ]
        task.add_description 'Migrate and then immediately rollback'

        # Setup the database from nothing
        task = Rake::Task.define_task :setup => [ :create, :migrate, :seed ]
        task.add_description 'Create the database and run all migrations'

        # Setup the database from nothing
        task = Rake::Task.define_task :rebuild => [ :drop, :setup ]
        task.add_description 'Drop and recreate the database'
      end
    end

    def migration_dll
      "#{solution.migrator.project_dir}/bin/#{solution.compile.configuration}/#{solution.migrator.project}.dll"
    end

    def tool_in_output_folder
      existing_path "#{solution.migrator.project_dir}/bin/#{solution.compile.configuration}/Migrate.exe"
    end

    def tool_in_nuget_package
      existing_path "#{solution.nuget.restore_location}/FluentMigrator.*/tools/Migrate.exe"
    end

    def existing_path(path)
      return path if FileList[path].any? { |p| File.exists? p }
      nil
    end

    def add_new_migration_task
      namespace :db do
        task = Rake::Task.define_task :new_migration, :name, :description do |t, args|
          name, description = args[:name], args[:description]

          unless name
            abort [
              %Q{Usage: rake "#{t.name}[name[,description]]"},
              desc,
            ].join "\n\n"
          end

          project, project_dir, project_file = solution.migrator.project, solution.migrator.project_dir, solution.migrator.project_file
          version = migration_version
          migration_file_name = "#{version}_#{name}.cs"
          migration_content = migration_template(version, name, description, project)

          # Save the new migration file
          save_file migration_content, "#{project_dir}/Migrations/#{migration_file_name}"

          # Add the new migration file to the project
          Albacore::Project.new(project_file).tap do |p|
            p.add_compile_node :Migrations, migration_file_name
            p.save
          end
        end
        task.add_description 'Creates a new migration file with the specified name'
      end
    end

    def migration_version
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end

    def migration_template(version, name, description, project_name)
      description = ", \"#{description}\"" unless description.nil?
      return <<TEMPLATE
using FluentMigrator;
using FluentMigrator.Runner;

namespace #{project_name}.Migrations
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
  end
end