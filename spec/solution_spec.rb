require 'cruxrake'

describe CruxRake::CompileConfig do

  describe 'By default' do
    before(:all) { @config = CruxRake::CompileConfig.new }

    it 'should set the build configuration to Release' do
      expect(@config.opts.configuration).to eq('Release')
    end
  end
end