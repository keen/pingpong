class ConsoleCheckLogger
  class << self
    def log(config, check, properties)
      config.logger.info("CheckLog, #{properties.inspect}")
    end
  end
end
