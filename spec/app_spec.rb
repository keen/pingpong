require 'spec_helper'
require 'rack/test'

describe Sinatra::Application do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "when authentication is on" do
    it 'fails when no credentials are given' do
      get '/'
      expect(last_response).to_not be_ok
    end

    it 'fails when invalid credentials are given' do
      authorize 'fub', 'buf'
      get '/'
      expect(last_response).to_not be_ok
    end

    it 'succeeds when valid credentials are given' do
      authorize 'foo', 'bar'
      get '/'
      expect(last_response).to be_ok
    end
  end
end
