require "db"
require "sqlite3"
require "mutex"
require "time"
require "json"
require "log"
require "./store_interface"
require "./constants"
require "./models/article_content"

module Azurite
  class Store
    include StoreInterface

    @db : DB::Database
    @config : Config
    @mutex : Mutex
    @auto_cleanup_enabled : Bool
    @auto_cleanup_interval : Time::Span
    @cleanup_channel : ::Channel(Nil)

    def initialize(@config : Config)
      validate_db_path
      @mutex = Mutex.new
      @auto_cleanup_enabled = false
      @auto_cleanup_interval = AUTO_CLEANUP_INTERVAL_DEFAULT
      @cleanup_channel = ::Channel(Nil).new
      @db = DB.open("sqlite3:#{@config.db_path}")
      init_schema
      AZURITE_LOG.info { "AzuriteStore initialized: #{@config.db_path}" }
    end

    private def synchronized(context : String? = nil, &)
      @mutex.synchronize { yield }
    rescue ex
      msg = context ? "Failed to #{context}" : "Database operation failed"
      AZURITE_LOG.error(exception: ex) { msg }
      raise ex
    end

    def start_auto_cleanup(interval : Time::Span = AUTO_CLEANUP_INTERVAL_DEFAULT) : Nil
      return if @auto_cleanup_enabled
      @auto_cleanup_enabled = true
      @auto_cleanup_interval = interval
      spawn_auto_cleanup
      AZURITE_LOG.info { "Auto cleanup started with interval: #{interval}" }
    end

    def stop_auto_cleanup : Nil
      return unless @auto_cleanup_enabled
      @auto_cleanup_enabled = false
      @cleanup_channel.send(nil)
      AZURITE_LOG.info { "Auto cleanup stopped" }
    end

    private def spawn_auto_cleanup
      spawn do
        loop do
          select
          when @cleanup_channel.receive
            break
          when timeout @auto_cleanup_interval
            if @auto_cleanup_enabled
              enforce_size_limits
            else
              break
            end
          end
        end
      end
    end

    private def validate_db_path
      dir = File.dirname(@config.db_path)
      if dir != "." && !Dir.exists?(dir)
        raise ArgumentError.new("Database directory does not exist: #{dir}")
      end
      if File.exists?(@config.db_path)
        info = File.info(@config.db_path)
        unless info.permissions.includes?(File::Permissions::OwnerWrite)
          raise ArgumentError.new("Database file is not writable: #{@config.db_path}")
        end
      end
    end

    private def init_schema
      @db.exec <<-SQL # ameba:disable Style/HeredocIndent
        CREATE TABLE IF NOT EXISTS #{TABLE_NAME} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_link TEXT UNIQUE NOT NULL,
          feed_url TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          content_type TEXT DEFAULT 'html',
          fetched_at TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        )
      SQL

      @db.exec("CREATE INDEX IF NOT EXISTS idx_content_link ON #{TABLE_NAME}(item_link)")
      @db.exec("CREATE INDEX IF NOT EXISTS idx_content_feed ON #{TABLE_NAME}(feed_url)")
      @db.exec("CREATE INDEX IF NOT EXISTS idx_content_created ON #{TABLE_NAME}(created_at)")
    end

    def store(item_link : String, feed_url : String, title : String, content : String, content_type : String = CONTENT_TYPE_DEFAULT) : Bool
      synchronized("store content for #{item_link}") do
        truncated_content = truncate_content(content)
        fetched_at = Time.utc.to_s(TIME_FORMAT)
        @db.exec(
          "INSERT INTO #{TABLE_NAME} (item_link, feed_url, title, content, content_type, fetched_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(item_link) DO UPDATE SET feed_url = excluded.feed_url, title = excluded.title, content = excluded.content, content_type = excluded.content_type, fetched_at = excluded.fetched_at",
          item_link, feed_url, title, truncated_content, content_type, fetched_at
        )
        true
      end
    end

    def get_content(item_link : String) : String?
      synchronized("get content for #{item_link}") do
        @db.query_one?(
          "SELECT content FROM #{TABLE_NAME} WHERE item_link = ? LIMIT 1",
          item_link,
          as: String
        )
      end
    end

    def get_article(item_link : String) : ArticleContent?
      synchronized("get article for #{item_link}") do
        @db.query_one?(
          "SELECT #{ARTICLE_CONTENT_COLUMNS} FROM #{TABLE_NAME} WHERE item_link = ? LIMIT 1",
          item_link
        ) do |result_set|
          ArticleContent.new(result_set)
        end
      end
    end

    def articles_for_feed(feed_url : String) : Array(ArticleContent)
      synchronized("get articles for feed #{feed_url}") do
        articles = [] of ArticleContent
        @db.query(
          "SELECT #{ARTICLE_CONTENT_COLUMNS} FROM #{TABLE_NAME} WHERE feed_url = ? ORDER BY created_at DESC",
          feed_url
        ) do |result_set|
          while result_set.move_next
            articles << ArticleContent.new(result_set)
          end
        end
        articles
      end || [] of ArticleContent
    end

    def cleanup_old_entries(retention_days : Int32? = nil) : Int32
      days = retention_days || @config.retention_days
      result = synchronized("cleanup old entries") do
        cutoff = (Time.utc - days.days).to_s(TIME_FORMAT)
        exec_result = @db.exec("DELETE FROM #{TABLE_NAME} WHERE created_at < ?", cutoff)
        exec_result.rows_affected.to_i32
      end
      if result && result > 0
        AZURITE_LOG.info { "Cleaned up #{result} old articles (older than #{days} days)" }
      end
      result || 0
    end

    def cleanup_low_quality_content(min_length : Int32) : Int32
      result = synchronized("cleanup low quality content") do
        exec_result = @db.exec("DELETE FROM #{TABLE_NAME} WHERE LENGTH(content) < ?", min_length)
        exec_result.rows_affected.to_i32
      end
      if result && result > 0
        AZURITE_LOG.info { "Cleaned up #{result} low-quality articles (content < #{min_length} chars)" }
        vacuum if db_size_mb > 10
      end
      result || 0
    end

    def db_size_mb : Float64
      return 0.0 unless File.exists?(@config.db_path)
      File.size(@config.db_path).to_f64 / BYTES_PER_MB
    end

    def enforce_size_limits : Nil
      current_size_mb = db_size_mb

      if current_size_mb > @config.hard_limit_mb
        AZURITE_LOG.warn { "Content DB size (#{current_size_mb.round(2)}MB) exceeds hard limit (#{@config.hard_limit_mb}MB), running aggressive cleanup..." }
        aggressive_cleanup
      elsif current_size_mb > @config.max_size_mb
        AZURITE_LOG.warn { "Content DB size (#{current_size_mb.round(2)}MB) exceeds soft limit (#{@config.max_size_mb}MB)" }
        cleanup_old_entries(@config.retention_days_fraction(SOFT_CLEANUP_DAYS_FRACTION))
      elsif current_size_mb > @config.warning_size_mb
        AZURITE_LOG.info { "Content DB size: #{current_size_mb.round(2)}MB (warning threshold: #{@config.warning_size_mb}MB)" }
      end
    end

    private def aggressive_cleanup
      cleanup_old_entries(@config.retention_days_fraction(AGGRESSIVE_CLEANUP_DAYS_FRACTION))
      vacuum
    end

    private def vacuum
      @db.exec("VACUUM")
      AZURITE_LOG.info { "Vacuumed content database" }
    end

    private def truncate_content(content : String) : String
      return content if content.bytesize <= @config.max_content_bytes

      # Content exceeds limit - truncate to max bytes, handling UTF-8 boundaries
      return content.byte_slice(0, @config.max_content_bytes) if content.valid_encoding?

      # Use binary search to find valid UTF-8 boundary
      max_bytes = @config.max_content_bytes
      lo = 0
      hi = max_bytes
      while lo < hi
        mid = (lo + hi + 1) // 2
        if content.byte_slice(0, mid).valid_encoding?
          lo = mid
        else
          hi = mid - 1
        end
      end
      content.byte_slice(0, lo)
    end

    def close : Nil
      stop_auto_cleanup
      @db.close
    end
  end
end
