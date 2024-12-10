# Adds a few additional behaviors into the application controller
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  before_action :authenticate_if_needed

  layout 'collection'

  protect_from_forgery with: :exception

  # Extra authentication for bulkrax
  def authenticate_if_needed
    # Disable this extra authentication in test mode
    return true if Rails.env.test?
    if (controller_path.include?('bulkrax'))
      authenticate_or_request_with_http_basic do |username, password|
        username == ENV['BULKRAX_USERNAME'] && password == ENV['BULKRAX_PW']
      end
    end
  end

  # redefines authenticate_user! to do nothing, which disables devise authentication for all controller actions throughout the app
  # removing the following 2 lines will re-enable devise auth
  def authenticate_user!
  end

  def current_user
    super || guest_user
  end
end
