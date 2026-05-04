module Azurite
  RETENTION_DAYS_DEFAULT        =        45
  MAX_SIZE_MB_DEFAULT           =        50
  WARNING_SIZE_MB_DEFAULT       =        30
  HARD_LIMIT_MB_DEFAULT         =       100
  MAX_CONTENT_BYTES_DEFAULT     = 1_048_576
  DB_PATH_DEFAULT               = "./content.db"
  CONTENT_TYPE_DEFAULT          = "html"
  TIME_FORMAT                   = "%Y-%m-%dT%H:%M:%SZ"
  TABLE_NAME                    = "article_content"
  ARTICLE_CONTENT_COLUMNS       = "item_link, feed_url, title, content, content_type, id, fetched_at, created_at"
  AUTO_CLEANUP_INTERVAL_DEFAULT = 1.hour

  # Validation
  MIN_VALID_VALUE = 1

  # Byte calculations
  BYTES_PER_MB = 1_048_576

  # For retention cleanup fractions
  SOFT_CLEANUP_DAYS_FRACTION       = 2
  AGGRESSIVE_CLEANUP_DAYS_FRACTION = 3

  # Logging
  AZURITE_LOG = Log.for("azurite")

  # Shared configuration for Builder and Store
  struct Config
    property db_path : String
    property retention_days : Int32
    property max_size_mb : Int32
    property warning_size_mb : Int32
    property hard_limit_mb : Int32
    property max_content_bytes : Int32

    def initialize(
      @db_path = DB_PATH_DEFAULT,
      @retention_days = RETENTION_DAYS_DEFAULT,
      @max_size_mb = MAX_SIZE_MB_DEFAULT,
      @warning_size_mb = WARNING_SIZE_MB_DEFAULT,
      @hard_limit_mb = HARD_LIMIT_MB_DEFAULT,
      @max_content_bytes = MAX_CONTENT_BYTES_DEFAULT,
    )
    end

    def retention_days_fraction(factor : Int32) : Int32
      ({@retention_days // factor, 1}).max
    end
  end
end
