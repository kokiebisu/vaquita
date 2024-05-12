require 'uri'
require 'net/http'

def create_request_obj(uri, cookie)
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:72.0) Gecko/20100101 Firefox/72.0"
  request["Accept"] = "*/*"
  request["Accept-Language"] = "en-US,en;q=0.5"
  request["Content-Type"] = "application/json"
  request["X-Goog-AuthUser"] = "0"
  request["x-origin"] = "https://music.youtube.com"
  request["Cookie"] = cookie

  return request
end
