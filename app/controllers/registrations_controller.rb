class RegistrationsController < Devise::RegistrationsController

  before_action :configure_permitted_parameters

  protected

    def after_sign_up_path_for(resource)
      edit_user_path(resource)
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) << :signed_waiver
    end

end