# Physique - Beautiful builds for .NET

Physique is an opinionated build framework that allows you to create a professional build process for your solution with minimal configuration.  You tell physique a little about your solution, and it creates a complete set of rake tasks to build, test and package your apps for deployment.

## Features

* Integrates with any unit testing framework. Provides built in support for [NUnit](http://www.nunit.org/) and [NSpec](http://nspec.org/).
* Support for packaging and publishing your assemblies as NuGet packages.
* Provides powerful developer workflow tools when paired with [FluentMigrator](https://github.com/schambers/fluentmigrator).
* Built-in support for packaging and publishing applications to [Octopus Deploy](https://octopusdeploy.com/)
* Built on top of [Albacore](http://github.com/Albacore/albacore) which provides a rich suite of build tools to support any project.
* Actively maintained with several companies using it in production.

## Getting Started with Physique

### Installing Ruby

You will need to [install Ruby](RUBY_SETUP.md) on your workstation and build servers.

### Project Structure

Physique was designed to minimize the amount of ceremony in defining a build process.  It uses a set of practical conventions that when followed, eliminate most of the configuration required to set up your builds.

Out of the box, Physique expects your repo to look something like this:

    ├─ build                              # Compiled files
    │  └─ packages                        # Compiled packages will be built here.
    ├─ docs                               # Documentation files
    ├─ lib                                # Included libraries
    ├─ src                                # Source folder
    │  ├─ packages                        # Nuget restore location
    │  ├─ .nuget                          # Nuget files
    │  │   └─ nuget.exe                   # Nuget executable
    │  ├─ YourProject                     # Project folder
    │  │  └─ YourProject.csproj           # Project file
    │  ├─ YourProject.Tests               # Test Project folder
    │  │  └─ YourProject.Tests.csproj     # Test Project file
    │  └─ YourProject.sln                 # Solution file
    ├─ tools                              # Tools and utilities
    └─ README.md

If your project doesn't look anything like this, don't worry, you can customize any of the conventions to match the structure of your solution.

### Preparing Your Project

* Open a command prompt and `cd` to the root of your repo.

* Create a `Gemfile` in the root and add the following:

    ```ruby
    source 'https://rubygems.org/'

    gem 'physique', '~> 0.3'
    ```

* Install the Bundler gem and install the required Ruby gems

    ```
    $ gem install bundler
    $ bundle install
    ```

* Physique uses the [semver2](https://github.com/haf/semver) gem to manage the version your solution. Use the included command line tool to create a `.semver` file for the solution.

    ```
    $ bundle exec semver init
    ```

* Create a `Rakefile` in the root and add the following:

    ```ruby
    require 'physique'

    Physique::Solution.new do |s|
      s.file = 'src/YourSolution.sln'
    end
    ```

* If everything is set up correctly you should be able to run the following and see a list of tasks that Physique has created for you.

    ```
    $ bundle exec rake --tasks

    rake compile          # Builds the solution
    rake compile:build    # Builds the solution using the Build target
    rake compile:clean    # Builds the solution using the Clean target
    rake compile:rebuild  # Builds the solution using the Rebuild target
    rake restore          # Restores all nugets as per the packages.config files
    rake test             # Run unit tests
    ```

* Now you can run your rake tasks.  For example, to compile your solution, run the following:

    ```
    $ bundle exec rake compile
    ```

## The Default Build Process

Physique's default build process consists of the following phases:

1. `version` - Determines the version of the build.
2. `restore` - Scans your repo for `packages.config` files and downloads the discovered packages to the Nuget restore location.
3. `compile` - Runs MSBuild on your solution file.
4. `test` - Scans your repo for test assemblies and runs all tests.
5. `package` - Packages your apps and/or assemblies for deployment.
6. `publish` - Publishes your packages to a Nuget repository.

Each phase depends on the ones before it.  This means when you run the tests, Physique will run the `restore` and `compile` tasks to ensure you your assemblies are up to date.  In addition, you can register custom tasks to run at the different phases of the build process.

## Customizing Your Build

Physique provides several customizations to tailor your build to your needs.  You configure these options in your `Rakefile` which is just a Ruby code file. Having the full power of the Ruby programming language at your disposal to define your builds is one of the best features of rake, and by extension Physique, over XML-based tools like NAnt or MSBuild.  If you don't know Ruby, never fear, Physique's configuration syntax is straightforward enough for any .NET developer to pick up quickly.

The following describes the available configuration options.  Unless otherwise specified, these examples show the default values.

### NuGet Configuration

You can customize how NuGet packages are handled in your solution.

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.use_nuget do |n|
    n.exe = 'src/.nuget/NuGet.exe'          # Path to the NuGet executable
    n.restore_location = 'src/packages'     # NuGet package restore location
    n.build_location = 'build/packages'     # Output folder for built NuGet packages
  end
end
```

### Compilation Configuration

You can customize MSBuild configuration and targets.

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.compilation do |c|
    c.default_targets = ['Clean', 'Rebuild']  # The default targets executed by the 'compile' task
    c.configuration = 'Release'               # The build configuration
    c.logging = 'normal'                      # MSBuild logging level
  end
end
```

If you have custom MSBuild targets you can tell Physique about them.

```ruby
s.compilation do |c|
  c.add_target 'Custom'
end
```

Physique will then add a rake task for each target which you can call from the command line.

```
$ bundle exec rake compile:custom
```

By default, Physique will create additional tasks for the Clean, Build and Rebuild targets.

### Unit Testing Configuration

To execute your tests, Physique will look for the test runner executable in the NuGet restore location at runtime. If multiple versions are available, the latest version will be used. Make sure that you include the NuGet package for the test runner in a `packages.config` file somewhere in your solution.

Physique supports NUnit by default, but also has built in support for NSpec.  Each of these test runners have their own defaults.  If you are using something different, it's easy to provide a custom configuration.

#### NUnit Configuration

Since NUnit is the default, no additional configuration is required to use it. Physique will automatically find and run any assembly ending in ".Tests".

To tweak this behavior, you have the following configuration options:

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.run_tests do |t|
    # Find all assemblies ending in '.Tests'
    t.files = FileList["**/*.Tests/bin/#{configuration}/*.Tests.dll"]

    # Default command line args
    t.parameters = ['/labels', '/trace=Verbose']
  end
end
```

#### NSpec Configuration

With the NSpec runner configured, Physique will automatically find and run any assembly ending in ".Specs".

Like wth NUnit, you have the following configuration options.  Note the runner must be set to `:nspec`.

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.run_tests do |t|
    t.runner = :nspec

    # The default method for finding NSpec assemblies
    t.files = FileList["**/*.Specs/bin/#{configuration}/*.Specs.dll"]

    # You can add additional command line args
    t.parameters = ['--failfast']
  end
end
```

#### Custom Configuration

You can use any unit testing framework. You just need to provide a bit more configuration.

```ruby
s.run_tests do |t|
  t.runner = :custom

  # Specify the test runner
  t.exe = 'root-relative-path/to/the/test-runner.exe'

  # Specify the test assemblies
  t.files = FileList["**/*.Tests/bin/#{configuration}/*.Tests.dll"]

  # Specify additional command line args
  t.parameters = ['/option1', '/option2']
end
```

### NuGet Publishing Configuration

Physique provides an easy way to publish your NuGet packages to public or private Nuget repos.  Each assembly in your solution will be published as a separate NuGet package with the correct dependencies.

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.publish_nugets do |p|
    # The NuGet repo you want to publish to
    p.feed_url = 'https://www.nuget.org'

    # The NuGet repo for your symbol package (Optional)
    p.symbols_feed_url = 'http://nuget.gw.symbolsource.org/Public/NuGet'

    # The API key to authenticate to the repo.
    # If your source code is public, make sure to pass this in as an environment variable.
    p.api_key = ENV['NUGET_API_KEY']

    # Metadata to be included in your Nuspec
    p.with_metadata do |m|
      m.description = 'Common libraries for crux applications'
      m.authors = 'Robert Scaduto, Leo Hernandez'
    end
  end
end
```

When you configure NuGet publishing, the `package` and `publish` tasks become available.

```
$ bundle exec rake --tasks
...
rake nuget:package        # Package all NuGets
rake nuget:publish        # Publish nuget packages to feed
rake nuget:publish:local  # Copy nuget packages to local path
...
```

## Third Party Tools

### FluentMigrator Configuration

If you are using FluentMigrator to manage your databases, Physique can create several useful tasks to improve your development workflow.  Simply tell Physique where your migrations project is located and it will take care of the rest.

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.fluently_migrate do |db|
    db.instance = '(local)'
    db.name = 'MyDatabase'
    db.project = 'src\MyProject.Database\MyProject.Database.csproj'
  end
end
```

Currently Physique only works with SQL Server, but support for additional databases is planned.

For more information, see [Using Physique with Fluent Migrator](FLUENT_MIGRATOR.md)

### Octopus Deploy Configuration

If you are deploying your applications with Octopus Deploy, Physique allows you to package and publish your applications without needing to modify your project file.

```ruby
Physique::Solution.new do |s|
  s.file = 'src/YourSolution.sln'

  s.octopus_deploy do |octo|
    # Octopus Deploy server's NuGet feed URL
    octo.server = 'http://octopus-deploy-server/nuget/packages'

    # Octopus Deploy API key
    # For security it's a good idea to pass this in as an environment variable.
    octo.api_key = ENV['OCTOPUS_API_KEY']

    # You can specify multiple apps to deploy

    # A hypothetical web application
    octo.deploy_app do |app|
      # App name for rake tasks
      app.name = 'web'

      # App type
      # Valid options include :service, :website, :console
      app.type = :website

      # App project file
      app.project = 'src/MyProject.Website/MyProject.Website.csproj'

      # Nuspec metadata for your application
      app.with_metadata do |m|
        m.description = 'My Web Application'
        m.authors = 'My Company, Inc.'
      end
    end
  end
end
```

When you configure Octopus deployments, the `octo:package` and `octo:publish` tasks become available.

The following tasks would be available with the configuration above:

```
$ bundle exec rake --tasks
...
rake octo:package       # Package all applications
rake octo:package:web   # Package MyProject.Website for Oct...
rake octo:publish       # Publish all apps to Octopus ...
rake octo:publish:web   # Publish MyProject.Website app to ...
...
```

## Roadmap

* Add conventions for more unit test frameworks.
* Add support for additional databases.
* Optionally use [Packet](https://github.com/fsprojects/Paket) instead of NuGet during `restore` phase
* Mono support is possible but completely untested.

## Support

Feel free to contact me [@scardetto](https://twitter.com/scardetto) if you have any questions.

## Contributing

1. Fork it ( https://github.com/scardetto/physique/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
