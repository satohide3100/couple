class ApplicationController < ActionController::Base
  # CSRF対策（LIFFトークン検証で代替）
  protect_from_forgery with: :exception, unless: -> { request.xhr? }

  before_action :set_csrf_token_header

  private

  def set_csrf_token_header
    response.headers['X-CSRF-Token'] = form_authenticity_token if request.xhr?
  end
end
