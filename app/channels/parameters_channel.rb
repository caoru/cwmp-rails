class ParametersChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "parameters:get"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
