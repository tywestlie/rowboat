module AiAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :require_ai_authorization
  end

  private

  def require_ai_authorization
    redirect_to new_ai_access_path unless session[:ai_authorized]
  end
end
