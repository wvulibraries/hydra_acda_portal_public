# Adds a few additional behaviors into the application controller
class ApplicationController < ActionController::Base
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  before_action :authenticate_if_needed

  layout 'collection'

  protect_from_forgery with: :exception

  # Extra authentication for bulkrax
  def authenticate_if_needed
    # Disable this extra authentication in test mode
    # return true if Rails.env.test?
    if (controller_path.include?('bulkrax'))
      authenticate_or_request_with_http_basic do |username, password|
        username == "wvu" && password == "hydra"
      end
    end
  end
end
