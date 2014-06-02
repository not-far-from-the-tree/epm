class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  end

  check_authorization unless: :devise_controller?
  rescue_from CanCan::AccessDenied do |exception|
   if current_user
     redirect_to root_url, alert: "Sorry, you don't have permission to do that."
   else
     redirect_to new_user_session_url
   end
  end

  protected

    def after_sign_in_path_for(user)
      if (user.has_role?(:participant) && !user.has_participant_fields?) || (user.sign_in_count < 3 && !user.has_full_profile?)
        return edit_user_path user
      end
      super user
    end

    def record_not_found
      render 'shared/404', status: 404
    end

end