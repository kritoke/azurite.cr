module Azurite
  RETENTION_DAYS_DEFAULT    =        45
  MAX_SIZE_MB_DEFAULT       =        50
  WARNING_SIZE_MB_DEFAULT   =        30
  HARD_LIMIT_MB_DEFAULT     =       100
  MAX_CONTENT_BYTES_DEFAULT = 1_048_576
  DB_PATH_DEFAULT           = "./content.db"
  CONTENT_TYPE_DEFAULT      = "html"
  TIME_FORMAT               = "%Y-%m-%dT%H:%M:%SZ"
  ARTICLE_CONTENT_COLUMNS   = "id, item_link, feed_url, title, content, content_type, fetched_at, created_at"
  AUTO_CLEANUP_INTERVAL_DEFAULT = 1.hour

  # For retention cleanup fractions
  SOFT_CLEANUP_DAYS_FRACTION = 2
  AGGRESSIVE_CLEANUP_DAYS_FRACTION = 3
end
