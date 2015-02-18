require 'physique'

Physique::Solution.new do |s|
  s.file = 'Basic.sln'

  s.use_nuget do |n|
    n.exe = '../.nuget/nuget.exe'
    n.restore_location = 'packages'
  end
end
