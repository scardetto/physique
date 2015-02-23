require 'support/shared_contexts/rake'

describe 'basic' do
  include_context 'rake'

  let(:build_tasks) { %w(versionizer compile compile:clean compile:build compile:rebuild) }

  it 'should create the build tasks' do
    build_tasks.each do |name|
      task_names.should include(name)
    end
  end

  describe 'the compile task' do
    let(:task) { rake['compile'] }

    it 'should run without error' do
      task.invoke
    end

    it 'should include restore as a prerequisite' do
      task.prerequisites.should include('restore')
    end
  end
end
