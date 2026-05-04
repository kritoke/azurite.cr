require "json"
require "time"
require "../constants"

module Azurite
  class ArticleContent
    include JSON::Serializable

    getter id : Int64?
    property item_link : String
    property feed_url : String
    property title : String
    property content : String
    property content_type : String
    property fetched_at : Time
    property created_at : Time

    def initialize(
      @item_link : String,
      @feed_url : String,
      @title : String,
      @content : String,
      @content_type : String = CONTENT_TYPE_DEFAULT,
    )
      @fetched_at = Time.utc
      @created_at = Time.utc
    end

    # Map from database result set - column order must match ARTICLE_CONTENT_COLUMNS
    def self.new(rs : DB::ResultSet)
      new(
        rs.read(String),    # item_link
        rs.read(String),    # feed_url
        rs.read(String),    # title
        rs.read(String),    # content
        rs.read(String),    # content_type
      ).tap do |a|
        a.id = rs.read(Int64)
        a.fetched_at = Time.parse(rs.read(String), TIME_FORMAT, Time::Location::UTC)
        a.created_at = Time.parse(rs.read(String), TIME_FORMAT, Time::Location::UTC)
      end
    end
  end
end