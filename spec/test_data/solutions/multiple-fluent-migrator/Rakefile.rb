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
    t.task_alias = 'client'
    t.instance = '(local)'
    t.name = 'MyDatabase'
    t.project = 'Basic.Migrations1\Basic.Migrations1.csproj'
  end

  s.fluently_migrate do |t|
    t.task_alias = 'server'
    t.instance = '(local)'
    t.name = 'MyDatabase'
    t.project = 'Basic.Migrations2\Basic.Migrations2.csproj'
  end
end
