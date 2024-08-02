class TrackBusJob < ApplicationJob
  queue_as :default

  def perform(subscriber)
    route = subscriber.route
    route_dir = subscriber.route_dir

    loop do
      bus_stops_data = fetch_bus_data(
        url: "https://tdx.transportdata.tw/api/basic/v2/Bus/StopOfRoute/City/Taipei/#{route}?%24filter=Direction%20eq%20#{route_dir}&%24format=JSON",
      )

      if bus_stops_data["code"] = "200"
        target_stop_seq = subscriber.target_stop

        target_stop_name = bus_stops_data["json"]["Stops"].filter { |stop| stop["StopSequence"] == target_stop_seq }.first["StopName"]["Zh_tw"]
        stops_before_target_stop_name = bus_stops_data["json"]["Stops"].filter { |stop| stop["StopSequence"] == target_stop_seq - 5 }.first["StopName"]["Zh_tw"]

        bus_arrival_time_data = fetch_bus_data(
          url: "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taipei/#{route}?%24filter=Direction%20eq%20#{route_dir}&%24format=JSON",
        )

        send_notif_if_bus_coming(subscriber.phone, route, target_stop_name, stops_before_target_stop_name, bus_arrival_time_data)
      end

      sleep(30)
    end
  end

  private

  def fetch_bus_data(url:, options: {})
    uri = URI.parse(url)
    timestamp = get_gmt_timestamp
    hmac = encode_by_hmac_sha1(value = "x-date: " + timestamp)

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"
    request["X-Date"] = timestamp
    request["Authorization"] = %Q(hmac username=\"#{ENV["TDX_APP_ID"]}\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\"#{hmac}\")

    req_options = {
      use_ssl: uri.scheme == "https",
    }.merge(options)

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    { code: response.code, json: parse_json_response(response) }
  end

  def get_gmt_timestamp
    Time.now.utc.strftime("%a, %d %b %Y %T GMT")
  end

  def encode_by_hmac_sha1(key = ENV["TDX_APP_KEY"], value)
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new("sha1"),
        key,
        value,
      )
    ).strip
  end

  def parse_json_response(response)
    JSON.parse(response.body.force_encoding("UTF-8"))
  rescue => e
    puts "JSON response parse error: #{e}"
  end

  def send_notif_if_stops_before_arrival_time_less_than_thirty_secs(phone, route, target_stop_name, stops_before_target_stop_name, response_data)
    if response_data["code"] = "200"
      stops_before_bus_arrival_time = response_data["json"].filter { |stop| stop["StopName"]["Zh_tw"] == stops_before_target_stop_name }.first["EstimateTime"]

      if stops_before_bus_arrival_time < 30
        send_notif(phone, "#{route}路線公車即將到達#{target_stop_name}")
        break
      end
    end
  end

  def send_notif(phone, message)
    @twilio_client.messages.create(
      from: "valid_twilio_provided_number",
      to: phone,
      body: message,
    )
  end
end
