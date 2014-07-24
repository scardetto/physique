require 'physique/project'

describe Physique::Project do
  it 'should echo the path when full project file name is provided' do
    project_name = 'test.csproj'
    expect(get_path(project_name)).to eq(project_name)
  end

  it 'should return the full path when partial project file name is provided' do
    project_name = 'TestProject.Domain'
    expect(get_path(project_name)).to eq("src/#{project_name}/#{project_name}.csproj")
  end

  it 'should handle multiple languages' do
    project_name = 'TestProject.Domain'
    language = 'vb'
    expect(get_path(project_name, language)).to eq("src/#{project_name}/#{project_name}.vbproj")

    language = 'fs'
    expect(get_path(project_name, language)).to eq("src/#{project_name}/#{project_name}.fsproj")
  end

  def get_path(name, ext = 'cs')
    ::Physique::Project.get_path(name, ext)
  end
end