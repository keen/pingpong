$stdout.sync = true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'

require './pingpong_config'
config = PingpongConfig

if http_username = config[:http_username]
  use Rack::Auth::Basic, "Pingpong Pros Only!" do |username, password|
    username == config[:http_username] and password == config[:http_password]
  end
end

get '/' do
  @checks = config.check_source.all(config)
  @config = config
  haml :index
end

unless config['skip_checks']
  Thread.new {
    config.check_scheduler.run(config)
  }
end
