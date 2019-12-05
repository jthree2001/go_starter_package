class Admin::AppInstancesController < Admin::ApplicationController

  def index
    respond_to do |format|
      format.html { }
      format.json {  }
      format.js { }
    end
  end

  def show
    switch_instances
  end

  private
  def set_app_instance
    
  end
end
