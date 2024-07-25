class SubscribersController < ApplicationController
  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(subscriber_params)

    if @subscriber.save
      TrackBusJob.perform_later(@subscriber)
      redirect_to new_subscriber_path, notice: "Create successfully"
    else
      flash.now[:alert] = "Failed to create"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:phone, :route, :route_dir, :targer_stop)
  end
end
