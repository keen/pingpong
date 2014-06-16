require 'spec_helper'

describe JsonCheckSource do
  it 'reads a json file' do
    PingpongConfig.properties[:json_check_source_file] = File.expand_path('../test_checks.json', __FILE__)
    checks = JsonCheckSource.all(PingpongConfig)
    expect(checks.length).to eq(2)
    expect(checks[0]).to be_a Check
    expect(checks[0].name).to eq('Test Web')
    expect(checks[0].frequency).to eq(30)
    expect(checks[1]).to be_a Check
    expect(checks[1].name).to eq('Test API')
    expect(checks[1].frequency).to eq(15)
  end

  it 'returns empty if it cannot find the file' do
    PingpongConfig.properties[:json_check_source_file] = 'notafile'
    expect(JsonCheckSource.all(PingpongConfig)).to eq([])
  end

  it 'returns empty if the file is not valid' do
    PingpongConfig.properties[:json_check_source_file] = File.expand_path('../invalid_checks.json', __FILE__)
    expect(JsonCheckSource.all(PingpongConfig)).to eq([])
  end
end
