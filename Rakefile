$stdout.sync = true
require 'bundler'

begin
  require 'rspec/core/rake_task'
  desc 'Run Rspec unit tests'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end
rescue LoadError
end

namespace :checks do
  desc 'Create a checks.json file'
  task :add do
    require 'multi_json'

    puts 'Enter a URL to check:'
    url = STDIN.gets.chomp
    puts 'Enter a friendly name for this check:'
    name = STDIN.gets.chomp
    puts 'How often, in seconds, to run this check? (leave blank for 60)'
    frequency = STDIN.gets.chomp

    file = File.expand_path('../checks.json',  __FILE__)
    if File.exists?(file)
      checks = MultiJson.load(File.read(file), :symbolize_keys => true)
    else
      checks = { :checks => [] }
    end

    checks[:checks] << {
      :name => name,
      :url => url,
      :frequency => frequency.to_i > 0 ? frequency.to_i : 60
    }

    File.open(file, 'w') do |f|
      f.write(MultiJson.dump(checks, :pretty => true))
    end

    puts "Check added to #{file}!"
  end

  desc 'Run checks; useful for a worker'
  task :run do
    require './pingpong_config'
    config = PingpongConfig
    config.check_scheduler.run(config)
  end

  desc 'Run checks once, useful for debugging'
  task :run_once, :filters do |task, args|
    require 'cgi'
    require './pingpong_config'
    config = PingpongConfig
    config.check_runner = SimpleCheckRunner
    config.check_logger = ConsoleCheckLogger
    filters = CGI::parse(args[:filters]) if args[:filters]
    config.check_scheduler.run_once(config, filters)
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

  desc 'Print Keen IO check counts'
  task :count do
    require './pingpong_config'
    config = PingpongConfig
    keen = config.check_logger.keen_client(config)
    result = keen.count(config[:keen][:collection], :group_by => 'check.name')
    puts MultiJson.dump(result, :pretty => true)
  end

  desc 'Print Keen IO check duration averages'
  task :duration do
    require './pingpong_config'
    config = PingpongConfig
    keen = config.check_logger.keen_client(config)
    results = keen.average(config[:keen][:collection],
                      :target_property => 'request.duration',
                      :group_by => 'check.name')
    results.each do |result|
      puts MultiJson.dump(result, :pretty => true)
    end
  end

  desc 'Extract Keen IO checks'
  task :extract do
    require './pingpong_config'
    require 'multi_json'
    config = PingpongConfig
    keen = config.check_logger.keen_client(config)
    results = keen.extraction(config[:keen][:collection], :latest => '100')
    results.each do |result|
      puts MultiJson.dump(result, :pretty => true)
    end
  end

  desc 'Delete Keen IO collection - use with caution!!; requires KEEN_MASTER_KEY to be set'
  task :delete do
    require './pingpong_config'
    config = PingpongConfig
    keen = config.check_logger.keen_client(config)
    result = keen.delete(config[:keen][:collection])
    puts MultiJson.dump(result, :pretty => true)
  end
end

task :default => :spec
task :test => [:spec]
