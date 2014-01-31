require 'multi_json'
require 'check'

class JsonCheckSource
  class << self

    attr_accessor :checks

    def all(config)

      if checks.nil? || config[:check_source_auto_reload]
        checks_path = config[:json_check_source_file]

        begin
          checks_file = File.read(checks_path)
        rescue => e
          config.logger.error(e)
          config.logger.error("The file #{checks_path} was not found. Please create this file or run 'foreman run rake checks:add' to generate one.")
          return []
        end

        begin
          json_checks = MultiJson.load(checks_file, :symbolize_keys => true)[:checks]
        rescue => e
          config.logger.error(e)
          config.logger.error("The file at #{checks_path} is not valid JSON.")
          return []
        end

        checks = json_checks.map { |json_check|
          Check.new(json_check)
        }
      end

      checks
    end
  end
end
