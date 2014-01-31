require 'spec_helper'

describe EnvironmentAwareCheckMarshaller do
  let(:now) { Time.new(0) }
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }

  it 'should marshal checks' do
    properties = EnvironmentAwareCheckMarshaller.to_properties(PingpongConfig, check, now, 100, 200, { :content_length => 300 })
    properties.should_not be_empty

    properties[:check].should_not be_nil
    properties[:check][:name].should == 'WebCheck'
    properties[:check][:url].should == 'http://bark.meow'
    properties[:check][:frequency].should == 10

    properties[:request].should_not be_nil
    properties[:request][:sent_at].should == now.utc

    properties[:response].should_not be_nil
    properties[:environment].should_not be_nil
    properties[:environment][:region].should == 'test-region'
    properties[:environment][:location].should == 'test-location'
    properties[:environment][:hostname].should == 'test-hostname'
    properties[:environment][:rack_env].should == 'test'

    properties[:response][:content_length].should == 300
  end

  it 'should remove properties that are nil' do
    properties = EnvironmentAwareCheckMarshaller.to_properties(PingpongConfig, check, now, 100, 200, { :content_length => nil })
    properties[:response].should_not have_key :content_length
  end
end
