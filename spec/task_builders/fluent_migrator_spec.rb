require 'support/shared_contexts/rake'

describe 'fluent-migrator' do
  include_context 'rake'

  let(:db_build_tasks) { %w(create drop migrate new_migration rebuild rollback seed setup try) }

  let(:db_specific_tasks) { db_build_tasks.map {|t| "db:mydatabase:#{t}" } }

  let(:build_tasks) { db_build_tasks.map {|t| "db:#{t}" } }

  it 'should create all of the db tasks' do
    build_tasks.each do |name|
      task_names.should include(name)
    end
  end

  it 'should create all of the db specific tasks' do
    db_specific_tasks.each do |name|
      task_names.should include(name)
    end
  end

  it 'should rebuild the database' do
    rake['db:rebuild'].invoke
  end

  describe 'when creating migrations' do
    let(:project_folder) { "Basic.Migrations" }
    let(:project_file) { "#{project_folder}/Basic.Migrations.csproj" }
    let!(:project_file_contents) { File.read(project_file) }

    it 'should create a new migration' do
      rake['db:new_migration'].invoke 'TestMigration', 'Test migration description'
    end

    after do
      # Delete the created migrations files
      FileUtils.rm_rf Dir.glob("#{project_folder}/Migrations/*")

      # Restore the project file to it's original state
      open(project_file, 'w') do |f|
        f.puts project_file_contents
      end
    end
  end
end

describe 'multiple-fluent-migrator' do
  include_context 'rake'

  let(:db_aliases) { %w(client server) }
  let(:build_tasks) { %w(create drop migrate new_migration rebuild rollback seed setup try) }
  let(:db_specific_tasks) { db_aliases.product(build_tasks).map {|db_alias, task| "db:#{db_alias}:#{task}"} }
  let(:global_tasks) { %w(db:create db:drop db:migrate db:rebuild db:seed db:setup) }

  it 'should create the global build tasks' do
    global_tasks.each do |name|
      task_names.should include(name)
    end
  end

  it 'should create the db specific tasks' do
    db_specific_tasks.each do |name|
      task_names.should include(name)
    end
  end
end
