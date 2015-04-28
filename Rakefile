$stdout.sync = true
require 'bundler'
require 'sinatra/activerecord/rake'

begin
  require 'rspec/core/rake_task'
  desc 'Run Rspec unit tests'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end
rescue LoadError
end

namespace :db do
  task :load_config do
    require './app'
  end
end

# make sure environment variables are loaded for keen tasks
namespace :keen do

  # $ foreman run rake workbench
  # or to open it automatically in the browser in OSX:
  # $ open `foreman run rake workbench`
  desc 'Print Keen IO workbench URL'
  task :workbench do
    require './pingpong_config'
    config = PingpongConfig
    puts "https://keen.io/project/#{config[:keen][:project_id]}/workbench"
  end
end

namespace :jobs do
  desc 'Schedule and run pushpop jobs'
  task :run do
    require 'pushpop'
    Dir.glob("#{File.dirname(__FILE__)}/jobs/**/*.rb").each { |file|
      require file
    }
    Pushpop.schedule
    Clockwork.manager.run
  end

  task :run_once do
    require 'pushpop'
    Dir.glob("#{File.dirname(__FILE__)}/jobs/**/*.rb").each { |file|
      require file
    }
    Pushpop.run
  end
end

task :default => :spec
task :test => [:spec]
