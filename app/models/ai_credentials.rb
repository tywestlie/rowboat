module AiCredentials
  class << self
    def access_code
      ENV["AI_ACCESS_CODE"].presence || Rails.application.credentials.ai_access_code
    end

    def anthropic_api_key
      ENV["ANTHROPIC_API_KEY"].presence || Rails.application.credentials.anthropic_api_key
    end
  end
end
