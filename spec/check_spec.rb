require 'spec_helper'

describe Check do
  let (:check) {
    Check.new(
      :name => 'foo',
      :url => 'http://keen.io',
      :frequency => 60,
      :custom => {
        :datacenter => "dc1"
      })
  }

  it 'should initialize with options' do
   check.name.should == 'foo'
  end

  it 'should require a name, url, and frequency' do
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

  it 'should require data for POST method' do
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
    it "should turn into an object" do
      check.to_hash.should == {
        :name => "foo",
        :url => "http://keen.io",
        :frequency => 60,
        :method => "GET",
        :data => nil,
        :custom => {
          :datacenter => "dc1"
        }
      }
    end
  end
end
