class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_current_user

  after_action :verify_authorized, unless: :skip_authorization_verification?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def set_current_user
    Current.user = current_user
  end

  # Devise usa este controller como base, mas não passa por Pundit.
  # Também não tenta verificar autorização quando a resposta já é de
  # negação/ausência (ex.: RecordNotFound levantado antes do authorize).
  def skip_authorization_verification?
    devise_controller? || [ 401, 403, 404 ].include?(response.status)
  end

  def user_not_authorized
    respond_to do |format|
      format.html { render "errors/forbidden", status: :forbidden }
      format.json { render json: { error: "Acesso não autorizado." }, status: :forbidden }
      format.any { head :forbidden }
    end
  end

  def record_not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found }
      format.json { render json: { error: "Registro não encontrado." }, status: :not_found }
      format.any { head :not_found }
    end
  end
end
