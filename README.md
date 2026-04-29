# Azurite

SQLite-based content storage library for RSS/Atom feed article content.

## Installation

```yaml
# shard.yml
dependencies:
  azurite:
    github: kritoke/azurite.cr
```

```crystal
require "azurite"
```

## API Reference

### Builder

Create a store instance using the fluent builder:

```crystal
store = Azurite::Builder.new
  .db_path("./content.db")           # Database path (default: "./content.db")
  .retention_days(45)                # Days to retain articles (default: 45)
  .max_size_mb(50)                   # Soft limit MB (default: 50)
  .warning_size_mb(30)               # Warning threshold MB (default: 30)
  .hard_limit_mb(100)                # Hard limit MB (default: 100)
  .max_content_bytes(1_048_576)      # Max article size (default: 1MB)
  .build
```

**All builder methods are optional** — defaults work out of the box:

```crystal
store = Azurite::Builder.new.build  # Uses all defaults
```

### Store Methods

#### `store(item_link, feed_url, title, content, content_type = "html") : Bool`

Store article content. Returns `true` on success, `false` on failure.

```crystal
store.store(
  "https://example.com/article",
  "https://example.com/feed.xml",
  "Article Title",
  "<p>Full article HTML content...</p>"
)
```

- `item_link`: Unique identifier for the article (URL)
- `feed_url`: Source feed URL
- `title`: Article title
- `content`: Full article HTML/text content
- `content_type`: Content MIME type (default: `"html"`)

#### `get_content(item_link) : String?`

Retrieve raw content string for an article.

```crystal
content = store.get_content("https://example.com/article")
# => "<p>Full article HTML content...</p>" or nil
```

#### `get_article(item_link) : ArticleContent?`

Retrieve full article record with metadata.

```crystal
article = store.get_article("https://example.com/article")
if article
  puts article.title       # => "Article Title"
  puts article.feed_url    # => "https://example.com/feed.xml"
  puts article.content      # => "<p>Full article...</p>"
  puts article.fetched_at   # => 2024-01-15 10:30:00 UTC
end
```

#### `articles_for_feed(feed_url) : Array(ArticleContent)`

Get all stored articles for a feed URL, newest first.

```crystal
articles = store.articles_for_feed("https://example.com/feed.xml")
articles.each do |article|
  puts article.title
end
```

#### `cleanup_old_entries(retention_days = 45) : Int32`

Delete articles older than retention period. Returns count of deleted articles.

```crystal
deleted = store.cleanup_old_entries
# => 12
```

#### `enforce_size_limits`

Automatically manage database size:
- **Above hard limit (100MB)**: Aggressive cleanup + VACUUM
- **Above soft limit (50MB)**: Cleanup with half retention period
- **Above warning (30MB)**: Log size only

```crystal
store.enforce_size_limits
```

#### `db_size_mb : Float64`

Current database size in megabytes.

```crystal
puts store.db_size_mb  # => 42.5
```

#### `close`

Close database connection.

```crystal
store.close
```

### ArticleContent Model

```crystal
class ArticleContent
  include JSON::Serializable

  property id : Int64?
  property item_link : String
  property feed_url : String
  property title : String
  property content : String
  property content_type : String
  property fetched_at : Time
  property created_at : Time
end
```

## Database Schema

```sql
CREATE TABLE article_content (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_link TEXT UNIQUE NOT NULL,
  feed_url TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  content_type TEXT DEFAULT 'html',
  fetched_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
)

CREATE INDEX idx_content_link ON article_content(item_link)
CREATE INDEX idx_content_feed ON article_content(feed_url)
CREATE INDEX idx_content_created ON article_content(created_at)
```

## Usage Example

```crystal
require "azurite"

# Create store with custom settings
store = Azurite::Builder.new
  .db_path("/var/data/content.db")
  .retention_days(30)
  .max_size_mb(100)
  .build

# Store an article
store.store(
  "https://example.com/my-article",
  "https://example.com/feed.xml",
  "My Article Title",
  "<p>Article body content here...</p>"
)

# Later, retrieve it
article = store.get_article("https://example.com/my-article")
puts article.content if article

# Periodically cleanup old content
deleted = store.cleanup_old_entries
puts "Cleaned up #{deleted} old articles"

# Monitor database size
puts "Database size: #{store.db_size_mb.round(2)} MB"

store.close
```

## Development

```bash
shards install
crystal spec
crystal tool format --check src/
```

## Dependencies

- [crystal-sqlite3](https://github.com/crystal-lang/crystal-sqlite3) ~> 0.22.0

## License

MIT