require 'spec_helper'

describe Check do
  let (:check) {
    Check.new(
      :name => 'foo',
      :url => 'http://keen.io',
      :frequency => 60,
      :save_body => true,
      :method => "GET",
      :http_username => 'borg',
      :http_password => 'isfutile',
      :custom_properties => {
        :datacenter => "dc1"
      })
  }

  it 'initializes with options' do
   expect(check.name).to eq('foo')
  end

  it 'requires a name, url, and frequency' do
    expect {
      Check.new(:name => 'Bob', :url => 'http://google.com').validate
    }.to raise_error
    expect {
      Check.new(:name => 'Bob', :frequency => 10).validate
    }.to raise_error
    expect {
      Check.new(:url => 'http://bob.com', :frequency => 10).validate
    }.to raise_error
  end

  it 'requires data for POST method' do
    expect {
      Check.new(
        :name => 'foo',
        :url => 'http://keen.io',
        :frequency => 10,
        :method => "POST"
      ).validate
    }.to raise_error
  end

  describe ".to_hash" do
    it "turns into an object" do
      expect(check.to_hash).to eq({
        :name => "foo",
        :url => "http://keen.io",
        :save_body => true,
        :frequency => 60,
        :method => "GET",
        :data => nil,
        :custom_properties => {
          :datacenter => "dc1"
        },
        :id => nil,
      })
    end
  end

  describe ".add_response_time" do
    let(:check) { Check.new(method: "GET", name: "foobar", url: "http://google.com") }

    it 'creates response times array' do
      expect{check.add_response_time(10)}.to change{check.response_times}.from(nil).to([10])
    end

    it 'only keeps the last 30' do
      35.times do
        check.add_response_time(10)
      end

      expect(check.response_times.length).to eq(30)
    end
  end

  describe ".add_response_code" do
    let(:check) { Check.new(method: "GET", name: "foobar", url: "http://google.com") }

    it 'creates response codes array' do
      expect{check.add_response_code(10)}.to change{check.response_codes}.from(nil).to([10])
    end

    it 'only keeps the last 30' do
      35.times do
        check.add_response_code(10)
      end

      expect(check.response_codes.length).to eq(30)
    end
  end
end
