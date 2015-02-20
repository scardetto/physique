# Using Physique with Fluent Migrator

Physique paired with FluentMigrator creates a great developer workflow for managing databases. as part of your build.

## Prerequisites

For the purposes of this guide we are making the following assumptions:

* You have already configured your solution to use Physique.

* You are using a SQL Server database.

  NOTE: Physique currently only works with SQL Server. Support for other databases is certainly possible, but not yet implemented.

* You have SQL Client Tools installed and available on your `PATH`.

  Physique uses `SQLCMD.exe` to execute scripts on the command line.

## Creating a FluentMigrator Project

Create a new database project and add the following files and folders:

    ├─ MyProject.Database
    │  ├─ _Scripts
    │  │   ├─ create.sql
    │  │   ├─ drop.sql
    │  │   └─ seed.sql
    │  └─ Migrations
    └─ MyProject.Database.csproj

In the `create.sql` script add the following:

```sql
-- Create the database
CREATE DATABASE $(DATABASE_NAME)
GO
```

In the `drop.sql` script add the following:

```sql
-- Drop the database
if EXISTS(select name from master.dbo.sysdatabases where name = '$(DATABASE_NAME)') begin
    drop database $(DATABASE_NAME)
end
GO
```

As you can see we are not specifying the database name in the scripts.  Instead, we are using a variable that will be substituted by Physique when we run our tasks.

## Configuring your Rakefile to use FluentMigrator

Open your Rakefile and add the following to your solution's config:

```ruby
Physique::Solution.new do |s|
  ...
  s.fluently_migrate do |db|
    db.instance = ENV['DATABASE_NAMN'] || '(local)'
    db.name = ENV['DATABASE_NAMN'] || 'MyDatabase'
    db.project = 'src/MyProject.Database/MyProject.Database.csproj'
    db.scripts_dir = '_Scripts'
    db.task_alias = 'my'
  end
end
```

Here we are telling Physique:

* We will be managing a database named 'MyDatabase' on the '(local)' instance.
* These settings can be overridden when the DATABASE_NAME and DATABASE_INSTANCE variables are present.
* The path to the project file where are migrations will be implemented.
* The folder within the migrations project that contains our workflow scripts.
* An alias to be used when naming the rake tasks for this database.

## FluentMigrator Tasks

Now we can run `bundle exec rake -T` to examine the tasks Physique has created for us.  It should look something like this:

```
rake compile                                 # Builds the solution
rake compile:build                           # Builds the solution using th...
rake compile:clean                           # Builds the solution using th...
rake compile:rebuild                         # Builds the solution using th...
rake db:create                               # Create all databases
rake db:drop                                 # Drop all databases
rake db:migrate                              # Migrates all databases to th...
rake db:my:create                            # Create the database
rake db:my:drop                              # Drop the database
rake db:my:migrate                           # Migrate database to the late...
rake db:my:new_migration[name,description]   # Create a new migration file ...
rake db:my:rebuild                           # Drop and recreate the database
rake db:my:rollback                          # Rollback the database to the...
rake db:my:seed                              # Seed the database with test ...
rake db:my:setup                             # Create the database and run ...
rake db:my:support-dbs                       # Executes support-dbs.sql on ...
rake db:my:try                               # Migrate and then immediately...
rake db:rebuild                              # Drop and recreate all databases
rake db:seed                                 # Seed all databases with test...
rake db:setup                                # Build all databases and migr...
rake restore                                 # Restores all nugets as per t...
rake test                                    # Run unit tests
```

That's a lot of tasks!

All of the FluentMigrator tasks are prefixed with `db` and within those tasks some of them have the prefix of `db:my`.  The reason for this is that Physique supports multiple database migrations projects in the same solution.  In our config, we gave this database a `task_alias` of `my` so all of those tasks operate on that database only.  The other tasks will operate on all of the databases in the solution at once.

Here's a break down of each task does. Note that if you change the alias in your config, the task names will be different.

### Basic Tasks

* `db:my:create` - Creates the database.
* `db:my:drop` - Drops the database.
* `db:my:seed` - Seeds the database with test data.

As you might have guessed, these three tasks simply execute the SQL scripts in your project's `_Scripts` folder.  You probably won't call these directly too often but they are required by the other tasks.

If you don't create these files in your project, FluentMigrator will provide a default implementation for you.  However it's recommended that you create the scripts so that you have fine grained control over these steps.

#### A Note About Seed Data

The seed script is the place for you to place all of the test data you will need for local development.  It's also a great way to provide a consistent set of test data that can be used during integration testing.

### Migration Tasks

* `db:my:migrate` - Builds the migrations DLL and migrates the database to the latest version.
* `db:my:rollback` - Builds the migrations DLL and rolls back the most recent migration.
* `db:my:try` - A `db:migrate` followed by a `db:rollback`.  With this task, you can test a migration that you are working on, then roll it back so that you can continue to add to it.

### Build Tasks

* `db:my:setup` - This task creates the DB, migrates it to the latest version, and executes the seed script to populate it with test data.
* `db:my:rebuild` - Drops the database, then executes a `db:my:setup`.  This task is useful in your Continuous Integration process for testing the integrity of your migrations.

### New Migration Task

* `db:my:new_migration[name,description]` - Creates a new migration class and adds it to the migrations project.

### Global Tasks

As mentioned previously, it's possible to have multiple FluentMigrator projects in the same solution.  Physique will create tasks for each database individually as well as a subset of global tasks that operate across all databases.

* `db:create` - Create all databases.
* `db:drop` - Drop all databases.
* `db:seed` - Seed all databases with test data.
* `db:migrate` - Migrate all databases to the latest version.
* `db:setup` - Create all databases, migrate them to the latest version and populate them with seed data.
* `db:rebuild` - Drop and setup all databases.

## Developer Workflow

### Starting Fresh

Let's say I'm a new developer and it's my first day on the job working on an existing project.  The team I joined (in their infinite wisdom) is using Physique to manage their build process.  The first thing I want to do is checkout the source, build it, build all of the databases locally and then run all of the unit tests to make sure my local copy is configured correctly.

Assuming I have ruby installed on my machine, all I need to do is run the following:

```
$ git checkout repo-url
$ bundle install
$ bundle exec rake test
```

Thats it!

"But I didn't run any of the database tasks," you might be asking.  That's true.  And therein lies the power behind Physique's build phases.  When you configure a migrations project in Physique, the `db:rebuild` step is automatically registered as a dependency of the `test` phase of the build.  So when you run your tests, all of your databases are built too.

There will be times when you will want to delete and rebuild your local databases: for example, if there were data model changes since your last pull, or if you were experimenting with some db changes on one branch, and need to switch to a different branch to work on something new.

To rebuild the databases:

```
bundle exec rake db:rebuild
```

### Creating a New Migration

To create a new migration inside your project, run the following:

```
rake db:my:new_migration[migration_name,"migration description"]
```

This will create a new FluentMigrator class and add it to the migrations project.  It will automatically add a timestamp to the filename and `MigrationAttribute` to ensure that your migrations are run in sequential order and don’t conflict with anyone else on your team.

```
NOTE: Because this task actually edits the project file, you should make sure that all of your changes are saved to disk before running it.
```

As you can see this task takes a few parameters.

* `migration_name` - This is the name of the Migration class you want to create.
* `migration_description` - (Optional) A description that will be stored in the VersionInfo table after the migration is applied.

As a hypothetical example, let’s say we wanted to create a new migration to add a new status column to the our Order table.  The command might look something like this.

```
rake db:my:new_migration[AddStatusToOrder, "Add a new status column to the order table"]
```

After running this task, the IDE will alert you that the project file has been modified.  Select Reload and you should see the new migration in the Migrations folder.  At this point, all that’s left to do is add your migration code to the `Up` method.

### Running Your Migrations

After creating a new migration, you will want to apply it to your local database.  Unsurprisingly, this is done by running:

```
bundle exec rake db:migrate
```

This will execute any migrations that have not yet been applied.

If you want to rollback the last migration applied, the following command will do the trick.

```
rake db:my:rollback
```

Notice we need to specify the database alias here as the rollback tasks cannot be globally applied to multiple databases.

It’s common (at least for me) while working on a migration, that you might want to test it, but continue working on it.  Physique provides a convenience task that will run a migration, then immediately roll it back so that you can continue modifying it.

```
rake db:my:try
```

## Happy Migrating!

At this point you should be a migration pro!  Feel free to contact me [@scardetto](https://twitter.com/scardetto) if you have any questions.