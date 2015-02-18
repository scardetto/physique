require 'support/shared_contexts/rake'

describe 'basic' do
  include_context 'rake'

  DEFAULT_TASK = 'default'

  let(:task) { rake[DEFAULT_TASK] }

  it 'should create the default task' do
    task_names.should include(DEFAULT_TASK)
  end

  it 'should run default task without error' do
    task.invoke
  end
end
