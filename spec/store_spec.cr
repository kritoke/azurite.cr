require "./spec_helper"

describe Azurite::Store do
  describe "#store and #get_content" do
    it "stores and retrieves content" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        result = store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Test Article",
          "<p>Test content</p>"
        )
        result.should be_true

        content = store.get_content("https://example.com/article1")
        content.should eq("<p>Test content</p>")

        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "updates existing content on conflict" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Original Title",
          "<p>Original content</p>"
        )

        store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Updated Title",
          "<p>Updated content</p>"
        )

        content = store.get_content("https://example.com/article1")
        content.should eq("<p>Updated content</p>")

        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "raises error when creating store with non-existent directory" do
      expect_raises(ArgumentError, "Database directory does not exist") do
        Azurite::Builder.new.db_path("/nonexistent/path/to/db.db").build
      end
    end
  end

  describe "#get_article" do
    it "retrieves full article with metadata" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Test Article",
          "<p>Test content</p>",
          "html"
        )

        article = store.get_article("https://example.com/article1")
        article.should_not be_nil
        article = article.as(Azurite::ArticleContent)
        article.item_link.should eq("https://example.com/article1")
        article.feed_url.should eq("https://example.com/feed.xml")
        article.title.should eq("Test Article")
        article.content.should eq("<p>Test content</p>")
        article.content_type.should eq("html")

        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "returns nil for non-existent article" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        article = store.get_article("https://example.com/nonexistent")
        article.should be_nil
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#articles_for_feed" do
    it "retrieves all articles for a feed" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.store("https://example.com/article1", "https://example.com/feed.xml", "Title 1", "Content 1")
        store.store("https://example.com/article2", "https://example.com/feed.xml", "Title 2", "Content 2")
        store.store("https://example.com/article3", "https://other.com/feed.xml", "Title 3", "Content 3")

        articles = store.articles_for_feed("https://example.com/feed.xml")
        articles.size.should eq(2)

        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "returns empty array for feed with no articles" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        articles = store.articles_for_feed("https://example.com/empty.xml")
        articles.size.should eq(0)
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#db_size_mb" do
    it "returns positive size after storing content" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Test",
          "<p>Content</p>" * 100
        )
        size = store.db_size_mb
        size.should be > 0.0
        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "returns positive size after storing content" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Test",
          "<p>Content</p>" * 100
        )
        size = store.db_size_mb
        size.should be > 0.0
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#cleanup_old_entries" do
    it "deletes articles older than retention period" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new
          .db_path(path)
          .retention_days(1)
          .build

        deleted = store.cleanup_old_entries
        deleted.should eq(0)

        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "respects custom retention days" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        deleted = store.cleanup_old_entries(0)
        deleted.should eq(0)
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#enforce_size_limits" do
    it "runs without error" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.enforce_size_limits
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#close" do
    it "closes without error" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "can be called multiple times safely" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.close
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "auto cleanup" do
    it "starts and stops auto cleanup" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.start_auto_cleanup(1.second)
        store.stop_auto_cleanup
        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "can be configured via builder" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new
          .db_path(path)
          .auto_cleanup_interval(1.second)
          .build
        store.stop_auto_cleanup
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "path validation" do
    it "raises error for non-existent directory" do
      expect_raises(ArgumentError, "Database directory does not exist") do
        Azurite::Builder.new.db_path("/nonexistent/path/db.db").build
      end
    end
  end

  describe "content truncation" do
    it "truncates large content" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new
          .db_path(path)
          .max_content_bytes(100)
          .build

        large_content = "x" * 200
        store.store(
          "https://example.com/article1",
          "https://example.com/feed.xml",
          "Title",
          large_content
        )

        content = store.get_content("https://example.com/article1")
        content.should_not be_nil
        content = content.as(String)
        content.size.should be <= 100

        store.close
      ensure
        cleanup_db(path)
      end
    end
  end
end
