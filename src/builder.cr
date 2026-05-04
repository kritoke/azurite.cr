require "./constants"

module Azurite
  class Builder
    @db_path : String = DB_PATH_DEFAULT
    @retention_days : Int32 = RETENTION_DAYS_DEFAULT
    @max_size_mb : Int32 = MAX_SIZE_MB_DEFAULT
    @warning_size_mb : Int32 = WARNING_SIZE_MB_DEFAULT
    @hard_limit_mb : Int32 = HARD_LIMIT_MB_DEFAULT
    @max_content_bytes : Int32 = MAX_CONTENT_BYTES_DEFAULT
    @auto_cleanup_interval : Time::Span?

    private VALIDATORS = {
      retention_days:    "retention_days must be at least 1",
      max_size_mb:       "max_size_mb must be positive",
      warning_size_mb:   "warning_size_mb must be at least 1",
      hard_limit_mb:     "hard_limit_mb must be at least 1",
      max_content_bytes: "max_content_bytes must be at least 1",
    }

    private macro validate_and_set(name)
      def {{name.id}}(value : Int32) : self
        raise ArgumentError.new(VALIDATORS[:{{name.id}}]) if value < 1
        @{{name.id}} = value
        self
      end
    end

    validate_and_set(retention_days)
    validate_and_set(max_size_mb)
    validate_and_set(warning_size_mb)
    validate_and_set(hard_limit_mb)
    validate_and_set(max_content_bytes)

    def db_path(path : String) : self
      @db_path = path
      self
    end

    def auto_cleanup_interval(interval : Time::Span) : self
      @auto_cleanup_interval = interval
      self
    end

    def build : Store
      store = Store.new(
        @db_path,
        @retention_days,
        @max_size_mb,
        @warning_size_mb,
        @hard_limit_mb,
        @max_content_bytes
      )
      if interval = @auto_cleanup_interval
        store.start_auto_cleanup(interval)
      end
      store
    end
  end
end
