require 'rake'

shared_context 'rake' do
  let(:rake) { Rake::Application.new }
  let(:solution_name) { self.class.top_level_description }
  let(:solution_dir) { "spec/test_data/solutions/#{solution_name}" }

  before do
    @original_app = Rake.application
    Dir.chdir(solution_dir)
    Rake.application = rake
    Rake.load_rakefile('Rakefile.rb')
  end

  after do
    Rake.application = @original_app
    Dir.chdir(@original_app.original_dir)
  end
end