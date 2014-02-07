require 'spec_helper'
require 'rack/test'

describe Sinatra::Application do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "when authentication is on" do
    it 'should fail if no credentials are given' do
      get '/'
      last_response.should_not be_ok
    end

    it 'should fail if invalid credentials are given' do
      authorize 'fub', 'buf'
      get '/'
      last_response.should_not be_ok
    end

    it 'should success if valid credentials are given' do
      authorize 'foo', 'bar'
      get '/'
      last_response.should be_ok
    end
  end
end
