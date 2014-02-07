require 'webmock/rspec'

$: << File.join(File.dirname(__FILE__), 'lib')

ENV['RACK_ENV'] ||= 'test'

# require implementations of components first
Dir["#{File.expand_path('../../lib/*', __FILE__)}.rb"].each {|file| require file }

# then require configuration
require File.expand_path('../../pingpong_config.rb', __FILE__)

# then require sinatra app
require File.expand_path('../../app.rb', __FILE__)
