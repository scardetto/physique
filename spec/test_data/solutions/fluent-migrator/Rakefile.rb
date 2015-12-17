require 'physique'

Physique::Solution.new do |s|
  s.file = 'Basic.sln'

  s.use_nuget do |n|
    n.exe = '../.nuget/nuget.exe'
    n.restore_location = 'packages'
  end

  s.run_tests do |t|
    t.runner = :nspec
  end

  s.fluently_migrate do |t|
    t.instance = ENV['DATABASE_INSTANCE'] || '(local)'
    t.name = 'MyDatabase'
    t.project = 'Basic.Migrations/Basic.Migrations.csproj'
  end
end
