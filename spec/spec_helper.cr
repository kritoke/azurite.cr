require "spec"
require "../src/azurite"

def temp_db_path
  "/tmp/test_azurite_#{Random::Secure.urlsafe_base64(8)}.db"
end

def cleanup_db(path : String)
  # Validate path is within allowed /tmp directory to prevent path traversal
  normalized = File.expand_path(path)
  return unless normalized.starts_with?("/tmp/")
  File.delete(normalized) if File.exists?(normalized)
end
