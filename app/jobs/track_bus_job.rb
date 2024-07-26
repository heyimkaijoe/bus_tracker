class TrackBusJob < ApplicationJob
  queue_as :default

  def perform(subscriber)
    loop do
      bus_data = fetch_bus_location(subscriber.route)
      bus_stop_index = bus_data["stops"].index { |stop| stop["name"] == subscriber.target_stop } # to be changed

      if bus_stop_index && bus_stop_index <= 5 && bus_stop_index >= 3 # to be changed
        send_notif(subscriber.phone, "#{subscriber.route}路線公車即將到達#{subscriber.targer_stop}")
        break
      end

      sleep(60)
    end
  end

  private

  def fetch_bus_location(route)
    uri = URI("bus_api_url") # to be changed
    response = Net::HTTP.get(uri) # need to add something in my header?
    JSON.parse(response)
  end

  def send_notif(phone, message)
    @twilio_client.messages.create(
      from: "valid_twilio_number", # to be changed
      to: phone,
      body: message,
    )
  end
end
