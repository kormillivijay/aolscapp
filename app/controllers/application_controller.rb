# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  add_crumb "Home", '/'

  before_filter :ensure_login

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  helper_method :current_user

  before_filter { |c| Authorization.current_user = c.current_user }

  def ensure_login
    unless current_user
      redirect_to(login_path)
    end
  end

def permission_denied
  flash[:notice] = "Sorry, you are not allowed to access that page."
  redirect_to root_url
end

  def current_user_session
    
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
end
