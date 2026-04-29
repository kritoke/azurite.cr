require "./spec_helper"

describe Azurite::ArticleContent do
  describe "#initialize" do
    it "creates an article with required fields" do
      article = Azurite::ArticleContent.new(
        "https://example.com/article",
        "https://example.com/feed.xml",
        "Test Title",
        "<p>Content</p>"
      )

      article.item_link.should eq("https://example.com/article")
      article.feed_url.should eq("https://example.com/feed.xml")
      article.title.should eq("Test Title")
      article.content.should eq("<p>Content</p>")
      article.content_type.should eq("html")
      article.fetched_at.should be_a(Time)
      article.created_at.should be_a(Time)
    end

    it "creates an article with custom content type" do
      article = Azurite::ArticleContent.new(
        "https://example.com/article",
        "https://example.com/feed.xml",
        "Test Title",
        "Plain text content",
        "text"
      )

      article.content_type.should eq("text")
    end
  end

  describe "#to_json" do
    it "serializes to JSON" do
      article = Azurite::ArticleContent.new(
        "https://example.com/article",
        "https://example.com/feed.xml",
        "Test Title",
        "<p>Content</p>"
      )

      json = article.to_json
      json.should contain("https://example.com/article")
      json.should contain("Test Title")
      json.should contain("html")
    end
  end

  describe "#from_json" do
    it "deserializes from JSON" do
      article = Azurite::ArticleContent.new(
        "https://example.com/article",
        "https://example.com/feed.xml",
        "Test Title",
        "<p>Content</p>"
      )

      json = article.to_json
      restored = Azurite::ArticleContent.from_json(json)

      restored.item_link.should eq(article.item_link)
      restored.feed_url.should eq(article.feed_url)
      restored.title.should eq(article.title)
      restored.content.should eq(article.content)
      restored.content_type.should eq(article.content_type)
    end
  end
end
