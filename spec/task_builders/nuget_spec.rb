require 'support/shared_contexts/rake'

describe 'basic' do
  include_context 'rake'

  RESTORE_TASK = 'restore'
  let(:task) { rake[RESTORE_TASK] }

  it 'should create the test task' do
    task_names.should include(RESTORE_TASK)
  end

  it 'should run without error' do
    task.invoke
  end
end
