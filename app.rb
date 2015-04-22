$stdout.sync = true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
# Adding this to make sure that Timezones get formatted correctly http://pivotallabs.com/utc-vs-ruby-activerecord-sinatra-heroku-and-postgres/
Time.zone = 'UTC'
ActiveRecord::Base.default_timezone = :utc
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
    errorMsg = check.errors.messages.values.join(" ")
    flash[:error] = "Could not save the new check. #{errorMsg}"
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
  check.save_body = params[:save_body] == 'true'
  check.http_username = params[:http_username]
  check.http_password = params[:http_password]
  check.email_warn = params[:email_warn] == 'on'

  check
end

# This first check makes sure we don't run his when doing
# migrations or other rake tasks.
if File.split($0).last != 'rake'
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
end
