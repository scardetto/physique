require 'physique'

include Physique::ToolLocator

describe Physique::ToolLocator do
  if ::Rake::Win32.windows?
    it 'should find tools on the path' do
      result = which('ruby')
      expect(result).to eq('ruby')
    end

    it 'should find tool based on file spec' do
      result = locate_tool('C:/Program Files/Microsoft SQL Server/**/Tools/Binn/SQLCMD.EXE')
      expect(result).to eq('C:/Program Files/Microsoft SQL Server/110/Tools/Binn/SQLCMD.EXE')
    end

    it 'should find tool based on file spec' do
      result = Physique::ToolLocator.locate_tool('C:/Windows/Microsoft.NET/Framework/**/msbuild.exe')
      expect(result).to match(%r{v4.0}i)
    end
  end
end
