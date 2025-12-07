module Manages
  class OauthController < ApplicationController
    # Show OAuth setup page
    def setup
      @configured = Schedules::GoogleOauthService.configured?
      @authorized = Schedules::GoogleOauthService.authorized?
      
      if @configured && !@authorized
        @auth_url = Schedules::GoogleOauthService.authorization_url
      end
    end
    
    # Handle authorization code
    def callback
      code = params[:code]
      
      if code.present?
        if Schedules::GoogleOauthService.store_authorization_code(code)
          flash[:notice] = "✅ OAuth2 authorization successful! Google Meet integration is now active."
          redirect_to manages_oauth_setup_path
        else
          flash[:error] = "❌ Failed to store authorization. Please try again."
          redirect_to manages_oauth_setup_path
        end
      else
        flash[:error] = "❌ No authorization code received."
        redirect_to manages_oauth_setup_path
      end
    end
    
    # Reset authorization (for troubleshooting)
    def reset
      token_path = Rails.root.join("config", "google_oauth_token.yaml")
      if File.exist?(token_path)
        File.delete(token_path)
        flash[:notice] = "🔄 OAuth2 authorization has been reset. Please authorize again."
      else
        flash[:notice] = "No authorization to reset."
      end
      redirect_to manages_oauth_setup_path
    end
  end
end
