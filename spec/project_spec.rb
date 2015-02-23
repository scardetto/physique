require 'physique/project_path_resolver'

Project = Physique::ProjectPathResolver

describe Project do
  it 'should echo the path when full project file name is provided' do
    project_name = 'test.csproj'
    expect(resolve(project_name)).to eq(project_name)
  end

  it 'should return the full path when partial project file name is provided' do
    project_name = 'TestProject.Domain'
    expect(resolve(project_name)).to eq("src/#{project_name}/#{project_name}.csproj")
  end

  it 'should handle multiple languages' do
    project_name = 'TestProject.Domain'
    language = 'vb'
    expect(resolve(project_name, language)).to eq("src/#{project_name}/#{project_name}.vbproj")

    language = 'fs'
    expect(resolve(project_name, language)).to eq("src/#{project_name}/#{project_name}.fsproj")
  end

  describe 'when overidding the default project dir' do
    before do
      Physique::ProjectPathResolver.project_dir = 'projects'
    end

    it 'should return the full path when partial project file name is provided' do
      project_name = 'TestProject.Domain'
      expect(resolve(project_name)).to eq("projects/#{project_name}/#{project_name}.csproj")
    end

    after do
      Project.project_dir = Project::DEFAULT_PROJECT_FOLDER
    end
  end

  def resolve(name, ext = 'cs')
    Project.resolve(name, ext)
  end
end