require 'spec_helper'

describe KeenCheckLogger do
  let(:check) { Check.new(:name => "WebCheck", :url => "http://bark.meow", :frequency => 10) }
  let(:response_properties) { { "field" => "value" } }
  let(:api_url) { "https://api.keen.io/3.0/projects/test-project-id/events/test-collection" }

  it "should post the event to keen asynchronously" do
    stub_request(:post, api_url).
      with(:body => { "field" => "value" }).
      to_return(:status => 200, :body => "{\"created\":true}")

    actually_ran = false
    failed_exception = nil 
    EM.run {
      KeenCheckLogger.log(PingpongConfig, check, response_properties).callback {
        begin
          WebMock.should have_requested(:post, api_url).with(
            :body => "{\"field\":\"value\"}")
        rescue => exception          
          failed_exception = exception
        ensure
          actually_ran = true
          EM.stop
        end
      }.errback {
        EM.stop
        fail
      }
    }
    actually_ran.should be_true
    failed_exception.should be_nil
  end

end
