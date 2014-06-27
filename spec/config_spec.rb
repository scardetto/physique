require 'cruxrake'

describe CruxRake::FluentMigratorConfig do
  it 'should find full project path when specifying the name and language' do
    project_name = 'Test.Database'
    opts = CruxRake::FluentMigratorConfig.new.tap { |c|
      c.project = project_name
      c.lang = :vb
    }.opts

    expect(opts.project_file).to eq("src/#{project_name}/#{project_name}.vbproj")
  end

  it 'should default to the cs programming language' do
    project_name = 'Test.Database'
    opts = CruxRake::FluentMigratorConfig.new.tap { |c|
      c.project = project_name
    }.opts

    expect(opts.project_file).to eq("src/#{project_name}/#{project_name}.csproj")
  end
end