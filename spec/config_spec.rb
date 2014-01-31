require 'spec_helper'

describe PingpongConfig do
  it 'should have a check runner' do
    PingpongConfig.check_runner.should == EventmachineCheckRunner
  end

  it 'should have a check marshaller' do
    PingpongConfig.check_marshaller.should == EnvironmentAwareCheckMarshaller
  end

  it 'should have a check logger' do
    PingpongConfig.check_logger.should == KeenCheckLogger
  end

  it 'should have a check source' do
    PingpongConfig.check_source.should == JsonCheckSource
  end
end
