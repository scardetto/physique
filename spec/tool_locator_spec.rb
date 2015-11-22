require 'physique'

include Physique::ToolLocator

describe Physique::ToolLocator do
  it 'should find tools on the path' do
    result = which('ruby')
    expect(result).to eq('ruby')
  end

  it 'should find tool based on file spec' do
    result = locate_tool('./spec/test_data/tool_locator/Program Files/Microsoft SQL Server/**/Tools/Binn/SQLCMD.exe.txt')
    expect(result).to eq('./spec/test_data/tool_locator/Program Files/Microsoft SQL Server/110/Tools/Binn/SQLCMD.exe.txt')
  end

  MS_BUILD_PATH = './spec/test_data/tool_locator/Windows/Microsoft.NET/Framework/**/MSBuild.exe.txt'

  it 'should find latest version of a tool based on file spec' do
    result = locate_tool(MS_BUILD_PATH)
    expect(result).to match(%r{v4.0}i)
  end

  it 'should find first version of a tool if specified' do
    result = locate_tool(MS_BUILD_PATH, find_latest: false)
    expect(result).to match(%r{v3.5}i)
  end
end
