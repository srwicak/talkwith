require "json"

# Custom JSON token store to avoid YAML serialization issues with Proc objects
# Implements the token store interface required by Google::Auth::UserAuthorizer
class JsonTokenStore
  def initialize(file:)
    @file = file
  end
  
  def load(id)
    return nil unless File.exist?(@file)
    
    begin
      data = JSON.parse(File.read(@file))
      token_data = data[id]
      return nil unless token_data
      
      # Return JSON string as expected by googleauth
      token_data.to_json
    rescue JSON::ParserError, Errno::ENOENT => e
      Rails.logger.error "Failed to load token: #{e.message}"
      nil
    end
  end
  
  def store(id, token)
    data = {}
    data = JSON.parse(File.read(@file)) if File.exist?(@file)
    
    # Handle both JSON string and hash/object inputs
    token_hash = if token.is_a?(String)
      JSON.parse(token)
    elsif token.is_a?(Hash)
      token
    else
      # It's a credentials object
      {
        "access_token" => token.access_token,
        "refresh_token" => token.refresh_token,
        "expires_at" => token.expires_at.to_i,
        "issued_at" => token.issued_at.to_i
      }
    end
    
    data[id] = token_hash
    File.write(@file, JSON.pretty_generate(data))
  end
  
  def delete(id)
    return unless File.exist?(@file)
    
    data = JSON.parse(File.read(@file))
    data.delete(id)
    File.write(@file, JSON.pretty_generate(data))
  end
end
