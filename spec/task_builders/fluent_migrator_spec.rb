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
