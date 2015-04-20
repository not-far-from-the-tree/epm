# https://github.com/plataformatec/devise/blob/master/app/controllers/devise/registrations_controller.rb
class RegistrationsController < Devise::RegistrationsController

  before_action :configure_permitted_parameters

  after_action :add_to_mailing_list, only: :create, if: "user_signed_in? && params[:add_to_mailing_list]"

  protected

    def configure_permitted_parameters
      # note: the params listed below are identical to in users controller update action + password and signed_waiver
      devise_parameter_sanitizer.for(:sign_up) { |u| u.permit :email, :password, :signed_waiver, :fname, :lname, :phone, :address, :snail_mail, :lat, :lng, :home_ward, ward_ids: [] }
    end

    def add_to_mailing_list
      # todo: add feature test for this
      current_user.add_to_mailing_list
    end

end