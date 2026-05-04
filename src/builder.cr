require "./constants"

module Azurite
  class Builder
    @config = Config.new
    @auto_cleanup_interval : Time::Span?

    private def validate_positive(name : String, value : Int32)
      raise ArgumentError.new("#{name} must be at least #{MIN_VALID_VALUE}") if value < MIN_VALID_VALUE
    end

    def db_path(path : String) : self
      @config.db_path = path
      self
    end

    def retention_days(days : Int32) : self
      validate_positive("retention_days", days)
      @config.retention_days = days
      self
    end

    def max_size_mb(size : Int32) : self
      validate_positive("max_size_mb", size)
      @config.max_size_mb = size
      self
    end

    def warning_size_mb(size : Int32) : self
      validate_positive("warning_size_mb", size)
      @config.warning_size_mb = size
      self
    end

    def hard_limit_mb(size : Int32) : self
      validate_positive("hard_limit_mb", size)
      @config.hard_limit_mb = size
      self
    end

    def max_content_bytes(bytes : Int32) : self
      validate_positive("max_content_bytes", bytes)
      @config.max_content_bytes = bytes
      self
    end

    def auto_cleanup_interval(interval : Time::Span) : self
      @auto_cleanup_interval = interval
      self
    end

    def build : Store
      store = Store.new(@config)
      if interval = @auto_cleanup_interval
        store.start_auto_cleanup(interval)
      end
      store
    end
  end
end
