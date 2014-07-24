require 'physique'

describe Physique::CompileConfig do

  describe 'By default' do
    before(:all) { @config = Physique::CompileConfig.new }

    it 'should set the build configuration to Release' do
      expect(@config.opts.configuration).to eq('Release')
    end
  end
end