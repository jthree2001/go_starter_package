class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  add_flash_types :error
  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session



  protected

  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    flash[:error] = "Invalid Authenticity Token. Reloading.... "
    @error = :csrf
    respond_to do |format|
      format.html { redirect_to root_path }
      format.js { render 'errors' }
      format.all { render json: exception.message}
    end
  end

  rescue_from *[SocketError, Errno::ECONNREFUSED, Net::ReadTimeout] do |exception|
    flash[:error] = "Networking Error: #{exception.message}"
    respond_to do |format|
      format.html { render 'errors', status: 503 }
      format.js { render 'errors', status: 503 }
      format.all { render json: exception.message}
    end
  end

  rescue_from  ActiveRecord::RecordNotFound do |exception|
    flash[:error] = "#{exception.message}"
    respond_to do |format|
      format.html { render 'errors', status: 404}
      format.js { render 'errors', status: 404 }
      format.all { render json: exception.message, status: 404 }
    end
  end
end
