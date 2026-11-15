class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Fail loudly when an action forgets its authorization check.
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  # Nobody can sign in yet: replaced by the session user with Twitch login.
  def current_user
    nil
  end

  def render_not_found
    render json: { error: "not_found" }, status: :not_found
  end

  def render_forbidden
    render json: { error: "forbidden" }, status: :forbidden
  end
end
