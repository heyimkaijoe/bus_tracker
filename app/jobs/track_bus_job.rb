class TrackBusJob < ApplicationJob
  queue_as :default

  def perform(subscriber)
    loop do
      stops_before_bus_arrival_time_data = fetch_stops_before_bus_arrival_time(subscriber.route, "Direction eq #{subscriber.route_dir}")
      if stops_before_bus_arrival_time_data["code"] = "200"
        stops_before_bus_arrival_time = stops_before_bus_arrival_time_data["json"].filter { |stop| stop["StopName"]["Zh_tw"] == "三民健康路口(西松高中)" }.first["EstimateTime"]

        if stops_before_bus_arrival_time < 30
          send_notif(subscriber.phone, "#{subscriber.route}路線公車即將到達博仁醫院")
          break
        end
      end

      sleep(30)
    end
  end

  private

  def fetch_stops_before_bus_arrival_time(route, filter = "")
    get_response(
      url: "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taipei/#{route}?%24filter=#{filter}&%24format=JSON"
    )
  end

  def get_response(url, options: {})
    uri = URI.parse(url)
    timestamp = get_gmt_timestamp
    hmac = encode_by_hmac_sha1(value = "x-date: " + timestamp)

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"
    request["X-Date"] = timestamp
    request["Authorization"] = %Q(hmac username=\"#{ENV["TWILIO_ACCOUNT_SID"]}\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\"#{hmac}\")

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

  def encode_by_hmac_sha1(token = ENV["TWILIO_AUTH_TOKEN"], value)
    Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new("sha1"),
        token,
        value
      )
    ).strip
  end

  def parse_json_response(response)
    JSON.parse(response.body.force_encoding("UTF-8"))
  rescue => e
    puts "JSON response parse error: #{e}"
  end

  def send_notif(phone, message)
    @twilio_client.messages.create(
      from: "valid_twilio_provided_number",
      to: phone,
      body: message,
    )
  end
end
