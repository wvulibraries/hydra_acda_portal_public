# Adds a few additional behaviors into the application controller
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::TokenBasedUser
  before_action :authenticate_if_needed

  # Catch permission errors (was brought in by Hydra::Controller::ControllerBehavior)
  rescue_from CanCan::AccessDenied, with: :deny_access

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
    @current_user || nil
  end

  # get the currently configured user identifier (was brought in by Hydra::Controller::ControllerBehavior)
  def user_key
    current_user.user_key if current_user
  end

  # Override this method if you wish to customize the way access is denied (was brought in by Hydra::Controller::ControllerBehavior)
  def deny_access(exception)
    if exception.action == :edit
      redirect_to(main_app.url_for(action: 'show'), alert: exception.message)
    elsif current_user and current_user.persisted?
      redirect_to main_app.root_path, alert: exception.message
    else
      session['user_return_to'] = request.url
      redirect_to main_app.new_user_session_path, alert: exception.message
    end
  end
end
