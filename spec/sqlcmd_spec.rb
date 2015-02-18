require 'physique'
require 'physique/tasks/sqlcmd'

describe Physique::SqlCmd::Config do
  if ::Rake::Win32.windows?
    describe 'When initialized with the minimum required values' do
      before(:all) do
        @opts = Physique::SqlCmd::Config.new.tap { |c|
          c.server_name = 'server'
          c.command = 'command'
        }.opts
      end

      it 'should find sqlcmd tool' do
        expect(@opts[:exe]).to match(/sqlcmd/i)
      end

      it 'should break on errors' do
        expect(@opts[:continue_on_errors]).to be_false
      end

      it 'should set the server name' do
        expect(@opts[:server_name]).to eq('server')
      end
    end

    describe 'When initialized with a command' do
      before(:all) do
        @opts = Physique::SqlCmd::Config.new.tap { |c|
          c.server_name = 'server'
          c.command = 'command'
        }.opts
      end

      it 'should set the command' do
        expect(@opts[:command]).to eq('command')
      end

      it 'should set the source to :command' do
        expect(@opts[:source]).to eq(:command)
      end
    end

    describe 'When initialized with a file' do
      before(:all) do
        @opts = Physique::SqlCmd::Config.new.tap { |c|
          c.server_name = 'server'
          c.file = 'test.sql'
        }.opts
      end

      it 'should set the file' do
        expect(@opts[:file]).to eq('test.sql')
      end

      it 'should set the source to :file' do
        expect(@opts[:source]).to eq(:file)
      end
    end

    describe 'When initialized with both a file and a command' do
      before(:all) do
        @opts = Physique::SqlCmd::Config.new.tap { |c|
          c.server_name = 'server'
          c.command = 'command'
          c.file = 'file'
        }.opts
      end

      it 'should give precedence to the command' do
        expect(@opts[:source]).to eq(:command)
      end
    end
  end
end

describe Physique::SqlCmd::Cmd do
  describe 'When configured with a file' do
    before(:all) do
      opts = Physique::SqlCmd::Config.new.tap { |c|
        c.server_name = 'server'
        c.database_name = 'database'
        c.file = 'test.sql'
      }.opts

      @cmd = Physique::SqlCmd::Cmd.new opts
    end

    it 'should break on errors' do
      expect(@cmd.parameters).to include('-b')
    end

    it 'should include the server name' do
      expect(@cmd.parameters).to include('-S server')
    end

    it 'should include the database name' do
      expect(@cmd.parameters).to include('-d database')
    end

    it 'should include the file name' do
      expect(@cmd.parameters).to include('-i test.sql')
    end
  end

  describe 'When configured with a command' do
    before(:all) do
      opts = Physique::SqlCmd::Config.new.tap { |c|
        c.server_name = 'server'
        c.command = 'command'
      }.opts

      @cmd = Physique::SqlCmd::Cmd.new opts
    end

    it 'should break on errors' do
      expect(@cmd.parameters).to include('-b')
    end

    it 'should include the server name' do
      expect(@cmd.parameters).to include('-S server')
    end

    it 'should include the command in double quotes' do
      expect(@cmd.parameters).to include('-Q "command"')
    end
  end

  describe 'When setting variables' do
    before(:all) do
      opts = Physique::SqlCmd::Config.new.tap { |c|
        c.server_name = 'server'
        c.command = 'command'
        c.set_variable 'test_variable1', 'test_value1'
        c.set_variable 'test_variable2', 'test_value2'
      }.opts

      @cmd = Physique::SqlCmd::Cmd.new opts
    end

    it 'should add multiple variables to the command line' do
      expect(@cmd.parameters).to include('-v test_variable1=test_value1')
      expect(@cmd.parameters).to include('-v test_variable2=test_value2')
    end
  end
end
