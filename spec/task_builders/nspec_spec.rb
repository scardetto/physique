require 'support/shared_contexts/rake'

describe 'nspec' do
  include_context 'rake'

  TASK = 'test'

  let(:task) { rake[TASK] }

  it 'should run the test task without error' do
    task.invoke
  end
end
