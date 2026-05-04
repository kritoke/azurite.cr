require "./spec_helper"

describe Azurite::Builder do
  describe "#db_path" do
    it "sets the database path" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#retention_days" do
    it "sets retention days" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).retention_days(30).build
        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "raises for invalid retention days" do
      expect_raises(ArgumentError, "retention_days must be at least 1") do
        Azurite::Builder.new.retention_days(0)
      end
    end
  end

  describe "#max_size_mb" do
    it "raises for invalid max_size_mb" do
      expect_raises(ArgumentError, "max_size_mb must be at least 1") do
        Azurite::Builder.new.max_size_mb(0)
      end
    end
  end

  describe "#warning_size_mb" do
    it "raises for invalid warning_size_mb" do
      expect_raises(ArgumentError, "warning_size_mb must be at least 1") do
        Azurite::Builder.new.warning_size_mb(-1)
      end
    end
  end

  describe "#hard_limit_mb" do
    it "raises for invalid hard_limit_mb" do
      expect_raises(ArgumentError, "hard_limit_mb must be at least 1") do
        Azurite::Builder.new.hard_limit_mb(0)
      end
    end
  end

  describe "#max_content_bytes" do
    it "raises for invalid max_content_bytes" do
      expect_raises(ArgumentError, "max_content_bytes must be at least 1") do
        Azurite::Builder.new.max_content_bytes(0)
      end
    end
  end

  describe "#auto_cleanup_interval" do
    it "accepts Time::Span values" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new
          .db_path(path)
          .auto_cleanup_interval(2.hours)
          .build
        store.stop_auto_cleanup
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end

  describe "#build" do
    it "creates a Store with defaults" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.should be_a(Azurite::Store)
        store.close
      ensure
        cleanup_db(path)
      end
    end

    it "creates a Store implementing StoreInterface" do
      path = temp_db_path
      begin
        store = Azurite::Builder.new.db_path(path).build
        store.should be_a(Azurite::StoreInterface)
        store.close
      ensure
        cleanup_db(path)
      end
    end
  end
end
