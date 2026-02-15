# frozen_string_literal: true

module ApiAdaptor
  # Null logger that discards all log messages.
  #
  # This logger implements the Logger interface but does nothing with the messages,
  # sending them to the metaphorical /dev/null. Useful for testing or when logging
  # is not desired.
  #
  # @example Basic usage
  #   logger = NullLogger.new
  #   logger.info("This message is discarded")
  #
  # @example Service pattern with optional logging
  #   class SomeService
  #     def initialize(options = {})
  #       @logger = options[:logger] || NullLogger.new
  #     end
  #
  #     def perform
  #       @logger.debug { "do some work here" }
  #       # Work happens...
  #       @logger.info { "finished working" }
  #     end
  #   end
  #
  #   # With logging
  #   service = SomeService.new(logger: Logger.new($stdout))
  #   service.perform
  #
  #   # Silent (no logging)
  #   silent = SomeService.new  # Uses NullLogger by default
  #   silent.perform
  class NullLogger
    # Logs an unknown severity message (discarded)
    #
    # @param _args [Array] Message arguments (ignored)
    # @return [nil]
    def unknown(*_args)
      nil
    end

    # Logs a fatal message (discarded)
    #
    # @param _args [Array] Message arguments (ignored)
    # @return [nil]
    def fatal(*_args)
      nil
    end

    # @return [Boolean] false (fatal logging is never enabled)
    def fatal?
      false
    end

    # Logs an error message (discarded)
    #
    # @param _args [Array] Message arguments (ignored)
    # @return [nil]
    def error(*_args)
      nil
    end

    # @return [Boolean] false (error logging is never enabled)
    def error?
      false
    end

    # Logs a warning message (discarded)
    #
    # @param _args [Array] Message arguments (ignored)
    # @return [nil]
    def warn(*_args)
      nil
    end

    # @return [Boolean] false (warn logging is never enabled)
    def warn?
      false
    end

    # Logs an info message (discarded)
    #
    # @param _args [Array] Message arguments (ignored)
    # @return [nil]
    def info(*_args)
      nil
    end

    # @return [Boolean] false (info logging is never enabled)
    def info?
      false
    end

    # Logs a debug message (discarded)
    #
    # @param _args [Array] Message arguments (ignored)
    # @return [nil]
    def debug(*_args)
      nil
    end

    # @return [Boolean] false (debug logging is never enabled)
    def debug?
      false
    end
  end
end
