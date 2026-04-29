require "spec"
require "../src/azurite"

def temp_db_path
  "/tmp/test_azurite_#{Random::Secure.urlsafe_base64(8)}.db"
end

def cleanup_db(path : String)
  File.delete(path) if File.exists?(path)
end
