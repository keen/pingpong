require 'spec_helper'

describe EventmachineCheckRunner do
  let(:check_url) { 'http://bark.meow' }
  let(:check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10, :save_body => true) }
  let(:no_body_check) { Check.new(:name => 'WebCheck', :url => 'http://bark.meow', :frequency => 10) }
  let(:config) { PingpongConfig }

  it 'runs the check with eventmachine' do
    now = Time.now
    Time.stub(:now).and_return(now)
    stub_request(:get, check_url).
      to_return(:status => 200, :body => 'ok')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          expect(WebMock).to have_requested(:get, check_url)
          expect(start_time).to eq(now)
          expect(duration).to eq(0)
          expect(response[:status]).to eq(200)
          expect(response[:http_status]).to eq(200)
          expect(response[:content_length]).to eq('ok'.length)
          expect(response[:timed_out]).to be_false
          expect(response[:successful]).to be_true
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }
    expect(actually_ran).to be_true
    expect(failed_exception).to be_nil
  end

  it 'includes http authentication in headers' do
    now = Time.now
    Time.stub(:now).and_return(now)
    stub_request(:get, check_url).
      to_return(:status => 200, :body => 'ok')

    check.http_username = 'foo'
    check.http_password = 'bar'

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          expect(WebMock).to have_requested(:get, check_url).with(:headers => { :Authorization => ['bar', 'foo'] })
          expect(start_time).to eq(now)
          expect(duration).to eq(0)
          expect(response[:status]).to eq(200)
          expect(response[:http_status]).to eq(200)
          expect(response[:content_length]).to eq('ok'.length)
          expect(response[:timed_out]).to be_false
          expect(response[:successful]).to be_true
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }
    expect(actually_ran).to be_true
    expect(failed_exception).to be_nil
  end

  it 'sets timed_out to true and successful to false if status is 0' do
    now = Time.now
    Time.stub(:now).and_return(now)
    stub_request(:get, check_url).
        to_return(:status => 0, :body => '')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          expect(WebMock).to have_requested(:get, check_url)
          expect(start_time).to eq(now)
          expect(duration).to eq(0)
          expect(response[:status]).to eq(0)
          expect(response[:http_status]).to be_nil
          expect(response[:timed_out]).to be_true
          expect(response[:successful]).to be_false
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }
    expect(actually_ran).to be_true
    expect(failed_exception).to be_nil
  end

  it 'uses timeout settings from config' do
    stub_request(:get, check_url).
        to_return(:status => 200, :body => 'ok')

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do
        begin
          # also check that it's picking up our settings
          expect(config[:check_runner_connect_timeout]).to eq(15)
          expect(http.instance_variable_get(:@conn).instance_variable_get(:@connopts).instance_variable_get(:@connect_timeout)).to eq(15)
          expect(config[:check_runner_inactivity_timeout]).to eq(60)
          expect(http.instance_variable_get(:@conn).instance_variable_get(:@connopts).instance_variable_get(:@inactivity_timeout)).to eq(60)
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    expect(actually_ran).to be_true
    expect(failed_exception).to be_nil
  end

  it 'merges the response body into the event if the content type is json' do
    stub_request(:get, check_url).
      to_return(:status => 200, :body => '{"created":true}', :headers => { 'CONTENT-TYPE' => 'application/json; charset=utf-8' })

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, check) do |start_time, duration, response|
        begin
          expect(response[:body]["created"]).to be_true
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    expect(actually_ran).to be_true
    expect(failed_exception).to be_nil
  end

  it 'does not merge the response body into the event if the check says not to' do
    stub_request(:get, check_url).
      to_return(:status => 200, :body => '{"created":true}', :headers => { 'CONTENT-TYPE' => 'application/json' })

    actually_ran = false
    failed_exception = nil
    EM.run {
      http = EventmachineCheckRunner.run_check(PingpongConfig, no_body_check) do |start_time, duration, response|
        begin
          expect(response[:body]).to be_nil
        rescue => exception
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      end
    }

    expect(actually_ran).to be_true
    expect(failed_exception).to be_nil
  end
end
