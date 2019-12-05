class Api::V1::APIBaseController < ApplicationController
  around_filter :catch_exceptions
  before_filter :authenticate_app_api_request
  skip_before_filter :verify_authenticity_token
  skip_before_filter :authenticate_connect_app_request
  skip_after_filter :persist_connect_app_session
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  private

  def catch_exceptions
    yield
  rescue ActiveRecord::StatementInvalid => ex1
    puts "ActiveRecord::StatementInvalid from api base controller"
    puts ex1
    puts ex1.backtrace
    error = {:code => 422, :message => "Invalid Statement:  #{ex1.message}"}
    respond_to do |format|
      format.json { render json:  {"success" => false, "error" => error}, status: :unprocessable_entity }
    end
  rescue ActiveRecord::RecordNotFound => ex2
    puts "ActiveRecord::RecordNotFound from api base controller"
    puts ex2
    puts ex2.backtrace
    error = {:code => 404, :message => "Record not found"}
    respond_to do |format|
      format.json { render json: {"success" => false, "error" => error}, status: :not_found }
    end
  rescue ActionController::ParameterMissing => ex
    puts "ActionController::ParameterMissing from api base controller"
    puts ex
    puts ex.backtrace
    error = {:code => 422, :message => "Parameters Missing: #{ex.message}"}
    respond_to do |format|
      format.json { render json: {"success" => false, "error" => error}, status: :unauthorized }
    end
  rescue ActionController::UnpermittedParameters => ex4
    puts "ActionController::UnpermittedParameters from api base controller"
    puts ex4
    puts ex4.backtrace
    error = {:code => 422, :message => "Unpermitted Parameters: #{ex4.message}"}
    respond_to do |format|
      format.json { render json: {"success" => false, "error" => error}, status: :unauthorized }
    end
  rescue ActiveModel::ForbiddenAttributesError => ex
    puts "ActiveModel::ForbiddenAttributesError from api base controller"
    puts ex.backtrace
    error = {:code => 422, :message => "Forbidden Attributes: #{ex.message}"}
    respond_to do |format|
      format.json { render json: {"success" => false, "error" => error}, status: :unauthorized }
    end
  rescue ActiveRecord::RecordInvalid => ex
    puts "ActiveModel::RecordInvalid from api base controller"
    puts ex.backtrace
    error = {:code => 422, :message => "#{ex.message}"}
    respond_to do |format|
      format.json { render json: {"success" => false, "error" => error}, status: :unauthorized }
    end
  rescue => ex5
    puts "error from api base controller"
    puts ex5
    puts ex5.backtrace
    error = {:code => 500, :message => "Internal server error"}
    respond_to do |format|
      format.json { render json: {"success" => false, "error" => error}, status: :internal_server_error }
    end
  end

  protected

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
      headers['Access-Control-Max-Age'] = '1728000'
    end
  end

  def sanitize_date(date)
    if (date.length == 10 || date.length == 16)
      return Date.parse(date)
    elsif (date.length == 19 || date.length == 25)
      return DateTime.parse(date)
    else
      raise ActiveRecord::StatementInvalid.new("Incorrect date format. Please pass in 'YYYY-MM-DD' or 'YYYY-MM-DD HH:II:SS'")
    end
    return nil
  end
end
