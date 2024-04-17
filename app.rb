require 'sinatra'
require './lib/vaquita'

before do
  content_type :json
end

get '/' do
  "Hello, World!"
end

post '/process' do
  data = JSON.parse(request.body.read)
  url = data['url']
  stdout, stderr, status = Open3.capture3("./process.sh #{url}")
  if status.success?
    stdout
  else
    "Error: #{stderr}"
  end
end
