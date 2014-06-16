require 'spec_helper'

describe EnvironmentAwareCheckMarshaller do
  let(:now) { Time.new(0) }
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }

  it 'marshals checks' do
    properties = EnvironmentAwareCheckMarshaller.to_properties(PingpongConfig, check, now, 100, { :content_length => 300 })
    expect(properties).to_not be_empty

    expect(properties[:check]).to_not be_nil
    expect(properties[:check][:name]).to eq('WebCheck')
    expect(properties[:check][:url]).to eq('http://bark.meow')
    expect(properties[:check][:frequency]).to eq(10)

    expect(properties[:request]).to_not be_nil
    expect(properties[:request][:sent_at]).to eq(now.utc)

    expect(properties[:response]).to_not be_nil
    expect(properties[:environment]).to_not be_nil
    expect(properties[:environment][:region]).to eq('test-region')
    expect(properties[:environment][:location]).to eq('test-location')
    expect(properties[:environment][:hostname]).to eq('test-hostname')
    expect(properties[:environment][:rack_env]).to eq('test')

    expect(properties[:response][:content_length]).to eq(300)
  end

  it 'removes properties that are nil' do
    properties = EnvironmentAwareCheckMarshaller.to_properties(PingpongConfig, check, now, 100, { :content_length => nil })
    expect(properties[:response]).to_not have_key :content_length
  end
end
