class ApplicationController < ActionController::Base
  DEVICE_COOKIE = :cirilo_device

  before_action :identify_browser
  helper_method :current_learner

  private

  def current_learner
    @current_learner
  end

  def identify_browser
    response.headers["Cache-Control"] = "no-store"
    token = cookies.encrypted[DEVICE_COOKIE]
    @current_learner = Learner.for_device_token(token)

    unless @current_learner
      # A stale open form must not award, spend or reset progress under a new key.
      unless request.get? || request.head?
        message = "Прегледач више нема кључ за овај напредак. Освежи страницу да наставиш."
        if request.format.json?
          render json: { success: false, error: message }, status: :unprocessable_entity
        else
          render "errors/browser_identity", layout: false, status: :unprocessable_entity
        end
        return
      end
      # Old forms and flash messages must not carry over into a new identity.
      reset_session
      @current_learner, token = Learner.issue_device
    end

    # Renew on visits. Browser policy or deleting site data can still remove it.
    cookies.permanent.encrypted[DEVICE_COOKIE] = {
      value: token, httponly: true, same_site: :lax,
      secure: request.ssl? || Rails.env.production?, path: "/"
    }
  end
end
