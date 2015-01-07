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
  @config = config

  @checks = 
    [
      {
        name: "WebRootSSL",
        url: "https://keen.io/",
        frequency: 15,
        custom: {
          ssl: true,
          vhost: "web",
          resource: "index",
          lb: true
        }
      },
      {
        name: "dal05-app-0002-APIExtraction",
        url: "http://50.97.86.169:8009/3.0/projects/52f4849573f4bb7410000004/queries/extraction?api_key=927CC81EE9AD959A07EE61028B356C39&event_collection=logins&latest=100",
        frequency: 15,
        custom: {
          ssl: false,
          vhost: "api",
          resource: "extraction",
          dc: "dal05",
          lb: false,
          storm: true
        }
      }
    ]

  haml :index
end

get '/check/:name' do
  @config = config

  @check = {
    name: "WebRootSSL",
    url: "https://keen.io/",
    frequency: 15,
    custom: {
      ssl: true,
      vhost: "web",
      resource: "index",
      lb: true
    }
  }

  haml :check
end

unless config['skip_checks']
  Thread.new {
    config.check_scheduler.run(config)
  }
end

unless config['skip_pushpop']
  require 'pushpop'
  Dir.glob("#{File.dirname(__FILE__)}/jobs/**/*.rb").each { |file|
    require file
  }
  Pushpop.schedule
  Thread.new {
    Clockwork.manager.run
  }
end
