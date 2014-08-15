require 'forwardable'

class Check
  extend Forwardable

  attr_accessor :name
  attr_accessor :url
  attr_accessor :frequency
  attr_accessor :method
  attr_accessor :data
  attr_accessor :save_body
  attr_accessor :http_username
  attr_accessor :http_password

  attr_accessor :custom_properties

  def initialize(options)
    self.name = options[:name]
    self.url = options[:url]
    self.frequency = options[:frequency]
    self.method = (options[:method] || "GET").upcase
    self.data = options[:data]
    self.save_body = options[:save_body]
    self.http_username = options[:http_username]
    self.http_password = options[:http_password]

    self.custom_properties = options[:custom]

    raise "Check 'name' is required." unless self.name
    raise "Check 'url' is required." unless self.url
    raise "Check 'frequency' is required." unless self.frequency
    raise "Check 'method' must be one of POST or GET or DELETE." unless ["POST", "GET", "DELETE"].include? self.method
    raise "Check 'data' is required for POST method." if self.method == "POST" && self.data == nil
  end

  def to_hash
    { :name => self.name,
      :url => self.url,
      :frequency => self.frequency,
      :method => self.method,
      :data => self.data,
      :save_body => self.save_body,
      :custom => self.custom_properties }
  end
end
