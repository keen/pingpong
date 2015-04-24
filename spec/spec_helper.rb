require 'webmock/rspec'
require 'sinatra/activerecord'
require 'factory_girl'

$: << File.join(File.dirname(__FILE__), 'lib')

ENV['RACK_ENV'] ||= 'test'

# require implementations of components first
Dir["#{File.expand_path('../../lib/*', __FILE__)}.rb"].each {|file| require file }

# then require configuration
require File.expand_path('../../pingpong_config.rb', __FILE__)

# then require sinatra app
require File.expand_path('../../app.rb', __FILE__)

# then the factory_girl setup
require File.expand_path('../support/factory_girl.rb', __FILE__)

# then the factory files
require File.expand_path('../factories.rb', __FILE__)
#Dir["../factories/*.rb"].each {|file| require file }
