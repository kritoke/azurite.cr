require "./constants"

module Azurite
  class Builder
    @config = Config.new
    @auto_cleanup_interval : Time::Span?

    def db_path(path : String) : self
      @config.db_path = path
      self
    end

    def retention_days(days : Int32) : self
      @config.retention_days = days
      self
    end

    def max_size_mb(size : Int32) : self
      @config.max_size_mb = size
      self
    end

    def warning_size_mb(size : Int32) : self
      @config.warning_size_mb = size
      self
    end

    def hard_limit_mb(size : Int32) : self
      @config.hard_limit_mb = size
      self
    end

    def max_content_bytes(bytes : Int32) : self
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