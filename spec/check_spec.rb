require 'spec_helper'

describe Check do
  let (:check) {
    Check.new(
      :name => 'foo',
      :url => 'http://keen.io',
      :headers => {:'Accept' => 'application/json'},
      :frequency => 60,
      :save_body => true,
      :http_username => 'borg',
      :http_password => 'isfutile',
      :custom => {
        :datacenter => "dc1"
      })
  }

  it 'initializes with options' do
   expect(check.name).to eq('foo')
  end

  it 'requires a name, url, and frequency' do
    expect {
      Check.new(:name => 'Bob', :url => 'http://google.com')
    }.to raise_error
    expect {
      Check.new(:name => 'Bob', :frequency => 10)
    }.to raise_error
    expect {
      Check.new(:url => 'http://bob.com', :frequency => 10)
    }.to raise_error
  end

  it 'requires data for POST method' do
    expect {
      Check.new(
        :name => 'foo',
        :url => 'http://keen.io',
        :frequency => 10,
        :method => "POST"
      )
    }.to raise_error
  end

  describe "to_hash" do
    it "turns into an object" do
      expect(check.to_hash).to eq({
        :name => "foo",
        :url => "http://keen.io",
        :headers => {:'Accept' => 'application/json'},
        :save_body => true,
        :frequency => 60,
        :method => "GET",
        :data => nil,
        :custom => {
          :datacenter => "dc1"
        }
      })
    end
  end
end
