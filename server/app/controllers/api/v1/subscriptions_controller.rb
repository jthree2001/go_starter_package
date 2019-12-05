class Api::V1::SubscriptionsController < Api::V1::APIBaseController
  before_action :set_subscription, only:  [:show]
  def index
    @subscriptions = Subscription.all
    @unfiltered_size = @subscriptions.size
    if params[:page].nil?
      @page = 1
    else
      @page = params[:page].to_i
    end
    if params[:page_length].nil?
      @page_length = 20
    else
      @page_length = params[:page_length].to_i
    end
    @subscriptions = @subscriptions.page(@page).per_page(@page_length)
    respond_to do |format|
      format.json {render :status => :ok}
    end
  end

  def show
    respond_to do |format|
      format.json {render :status => :ok}
    end
  end

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end
end
