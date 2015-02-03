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
  @error = flash[:error]

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
  update_check(check, params)

  if check.save
    flash[:notice] = "Created a new check: #{params[:name]}"
    redirect '/'
  else
    flash[:error] = "Could not save the new check."
    redirect '/check/new'
  end
end

get '/check/:check_id/show' do
  @notice = flash[:notice]
  @config = config
  @check = Check.find(params[:check_id])

  haml :check
end

get '/check/:check_id/edit' do
  @config = config
  @check = Check.find(params[:check_id])

  haml :edit
end

post '/check/:check_id/update' do
  check = Check.find(params[:check_id])
  check = update_check(check, params)

  if check.nil?
    flash[:error] = "No such check to edit."
    redirect '/'
  else
    check.save!
    flash[:notice] = "Updated check: #{check.name}."
    redirect '/check/' + check.id.to_s + '/show'
  end
end

def update_check(check, params)
  check.name = params[:name]
  check.url = params[:url]
  check.method = params[:method]
  check.frequency = params[:frequency]
  check.custom_properties = params[:custom_properties]
  check.data = params[:data]
  check.http_username = params[:http_username]
  check.http_password = params[:http_password]

  check
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
