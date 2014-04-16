require 'spec_helper'

describe EventmachineCheckRunner do
  let(:check_url) { 'http://bark.meow' }
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10, :save_body => true) }
  let(:no_body_check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }
  let(:config) { PingpongConfig }

  it 'should run the check with eventmachine' do
    now = Time.now
    Time.stub(:now).and_return(now)
    stub_request(:get, check_url).
      to_return(:status => 200, :body => 'ok')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          WebMock.should have_requested(:get, check_url)
          start_time.should == now
          duration.should == 0
          response[:status].should == 200
          response[:http_status].should == 200
          response[:content_length].should == 'ok'.length
          response[:timed_out].should be_false
          response[:successful].should be_true
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }
    actually_ran.should be_true
    failed_exception.should be_nil
  end

  it 'should set timed_out to true and successful to false if status is 0' do
    now = Time.now
    Time.stub(:now).and_return(now)
    stub_request(:get, check_url).
        to_return(:status => 0, :body => '')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          WebMock.should have_requested(:get, check_url)
          start_time.should == now
          duration.should == 0
          response[:status].should == 0
          response[:http_status].should be_nil
          response[:timed_out].should be_true
          response[:successful].should be_false
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }
    actually_ran.should be_true
    failed_exception.should be_nil
  end

  it 'should use timeout settings from config' do
    stub_request(:get, check_url).
        to_return(:status => 200, :body => 'ok')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do
        begin
          # also check that it's picking up our settings
          config[:check_runner_connect_timeout].should == 15
          http.instance_variable_get(:@conn).instance_variable_get(:@connopts).instance_variable_get(:@connect_timeout).should == 15
          config[:check_runner_inactivity_timeout].should == 60
          http.instance_variable_get(:@conn).instance_variable_get(:@connopts).instance_variable_get(:@inactivity_timeout).should == 60
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    actually_ran.should be_true
    failed_exception.should be_nil
  end

  it 'should merge the response body into the event if the content type is json' do
    stub_request(:get, check_url).
      to_return(:status => 200, :body => '{"created":true}', :headers => { 'CONTENT-TYPE' => 'application/json; charset=utf-8' })

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          response[:body]["created"].should be_true
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    actually_ran.should be_true
    failed_exception.should be_nil
  end

  it 'should not merge the response body into the event if the check says not to' do
    stub_request(:get, check_url).
      to_return(:status => 200, :body => '{"created":true}', :headers => { 'CONTENT-TYPE' => 'application/json' })

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, no_body_check) do |start_time, duration, response|
        begin
          response[:body].should be_nil
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    actually_ran.should be_true
    failed_exception.should be_nil
  end
end
