$stdout.sync = true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'rack-flash'
require 'haml'

require './pingpong_config'
config = PingpongConfig

enable :sessions
use Rack::Flash

set :database_file, "database.yml"

if http_username = config[:http_username]
  use Rack::Auth::Basic, "Pingpong Pros Only!" do |username, password|
    username == config[:http_username] and password == config[:http_password]
  end
end

get '/' do
  @config = config
  @notice = flash[:notice]

  @checks = Check.all

  haml :index
end

get '/check/new' do
  @config = config
  @error = flash[:error]

  haml :new
end

post '/check/create' do
  check = Check.new
  check.name = params[:name]
  check.url = params[:url]
  check.method = params[:method]
  check.frequency = params[:frequency]
  check.custom_properties = params[:custom_properties]
  check.data = params[:data]
  check.http_username = params[:http_username]
  check.http_password = params[:http_password]

  if check.save
    flash[:notice] = "Created a new check: #{params[:name]}"
    redirect '/'
  else
    flash[:error] = "Could not save the new check."
    redirect '/check/new'
  end
end

get '/check/:check_id/show' do
  @config = config

  @check = {
    id: 1,
    name: "WebRootSSL",
    url: "https://keen.io/",
    method: "get",
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
