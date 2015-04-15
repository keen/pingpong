require 'yaml'
require 'erb'

$: << File.join(File.dirname(__FILE__), "lib")
Dir["#{File.expand_path("../lib/*", __FILE__)}.rb"].each {|file| require file }

class Hash
  def symbolize_keys_deep!
    keys.each do |k|
      ks = k.to_sym
      self[ks] = self.delete k
      self[ks].symbolize_keys_deep! if self[ks].kind_of? Hash
    end
  end
end

ENV['RACK_ENV'] ||= 'development'

yaml_env = YAML.load(ERB.new(File.read(File.expand_path('../config.yml', __FILE__))).result)[ENV['RACK_ENV']]
raise "NoConfigurationFound for RACK_ENV #{ENV['RACK_ENV']}" unless yaml_env

yaml_env.symbolize_keys_deep!

class PingpongConfig
  class << self
    attr_accessor :properties
    attr_accessor :check_scheduler
    attr_accessor :check_runner
    attr_accessor :check_logger
    attr_accessor :check_marshaller
    attr_accessor :logger

    def [](name)
      properties[name.to_sym]
    end
  end
end

# make sure to require any custom classes before this file is required
PingpongConfig.properties =        yaml_env
PingpongConfig.check_scheduler =   Object.const_get PingpongConfig[:check_scheduler]
PingpongConfig.check_runner =      Object.const_get PingpongConfig[:check_runner]
PingpongConfig.check_marshaller =  Object.const_get PingpongConfig[:check_marshaller]
PingpongConfig.check_logger =      Object.const_get PingpongConfig[:check_logger]
PingpongConfig.logger =            lambda {
                                    logger = Logger.new($stdout)
                                    if ENV['DEBUG']
                                      logger.level = Logger::DEBUG
                                    elsif ENV['RACK_ENV'] == "test"
                                      logger.level = Logger::FATAL
                                    else
                                      logger.level = Logger::INFO
                                    end
                                    logger
                                  }.call
