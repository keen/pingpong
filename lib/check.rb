require 'forwardable'

class Check
  extend Forwardable

  attr_accessor :name
  attr_accessor :url
  attr_accessor :frequency

  attr_accessor :custom_properties

  def initialize(options)
    self.name = options[:name]
    self.url = options[:url]
    self.frequency = options[:frequency]

    self.custom_properties = options[:custom]

    raise "Check 'name' is required." unless self.name
    raise "Check 'url' is required." unless self.url
    raise "Check 'frequency' is required." unless self.frequency
  end

  def to_hash
    { :name => self.name,
      :url => self.url,
      :frequency => self.frequency,
      :custom => self.custom_properties }
  end
end
