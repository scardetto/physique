require 'physique'

describe Physique::FluentMigratorConfig do

  it 'should throw when config is missing required values' do
    %w(instance= name= project= lang= scripts_dir=).each do |p|
      expect {
        default_config do |c|
          c.send p, nil
        end
      }.to raise_error(ArgumentError)
    end
  end

  it 'should default to the cs programming language' do
    project_name = 'Test.Database'
    opts = default_config do |c|
      c.project = 'Test.Database'
    end
    expect(opts.project_file).to eq("src/#{project_name}/#{project_name}.csproj")
  end

  it 'should find full project path when specifying the name and language' do
    project_name = 'Test.Database'
    opts = default_config do |c|
      c.lang = :vb
    end

    expect(opts.project_file).to eq("src/#{project_name}/#{project_name}.vbproj")
  end

  def default_config
    config = Physique::FluentMigratorConfig.new.tap do |c|
      c.instance = '(local)'
      c.name = 'TestDatabase'
      c.project = 'Test.Database'

      yield c if block_given?
    end
    config.opts
  end
end