require 'spec_helper'

describe JsonCheckSource do
  it 'should read a json file' do
    PingpongConfig.properties[:json_check_source_file] = File.expand_path('../test_checks.json', __FILE__)
    checks = JsonCheckSource.all(PingpongConfig)
    checks.length.should == 2
    checks[0].should be_a Check
    checks[0].name.should == 'Test Web'
    checks[0].frequency.should == 30
    checks[1].should be_a Check
    checks[1].name.should == 'Test API'
    checks[1].frequency.should == 15
  end

  it 'should return empty if it cannot find the file' do
    PingpongConfig.properties[:json_check_source_file] = 'notafile'
    JsonCheckSource.all(PingpongConfig).should == []
  end

  it 'should return empty if the file is not valid' do
    PingpongConfig.properties[:json_check_source_file] = File.expand_path('../invalid_checks.json', __FILE__)
    JsonCheckSource.all(PingpongConfig).should == []
  end
end
