module Users
  class RegistrationsController < ApplicationController
    allow_unauthenticated_access

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        flash[:notice] = "User created successfully."
        redirect_to new_user_session_path
      end
    end

    private

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
  end
end
