require "./constants"

module Azurite
  class Builder
    @config = Config.new
    @auto_cleanup_interval : Time::Span?

    private VALIDATORS = {
      retention_days:    "retention_days must be at least 1",
      max_size_mb:       "max_size_mb must be positive",
      warning_size_mb:   "warning_size_mb must be at least 1",
      hard_limit_mb:     "hard_limit_mb must be at least 1",
      max_content_bytes: "max_content_bytes must be at least 1",
    }

    private macro validate_and_set(field, key)
      def {{field.id}}(value : Int32) : self
        raise ArgumentError.new(VALIDATORS[{{key}}]) if value < MIN_VALID_VALUE
        @config.{{field.id}} = value
        self
      end
    end

    validate_and_set(retention_days, :retention_days)
    validate_and_set(max_size_mb, :max_size_mb)
    validate_and_set(warning_size_mb, :warning_size_mb)
    validate_and_set(hard_limit_mb, :hard_limit_mb)
    validate_and_set(max_content_bytes, :max_content_bytes)

    def db_path(path : String) : self
      @config.db_path = path
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