$stdout.sync = true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'

require './pingpong_config'
config = PingpongConfig

get '/' do
  @checks = config.check_source.all(config)
  @config = config
  haml :index
end

get '/checks' do
  @checks = config.check_source.all(config)
  @config = config
  haml :'checks/index'
end

unless config['skip_checks']
  Thread.new {
    config.check_scheduler.run(config)
  }
end
