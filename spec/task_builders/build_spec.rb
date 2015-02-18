require 'support/shared_contexts/rake'

describe 'basic' do
  include_context 'rake'

  BUILD_TASKS = %w(versionizer compile compile:clean compile:build compile:rebuild)

  it 'should create the build tasks' do
    BUILD_TASKS.each do |name|
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
