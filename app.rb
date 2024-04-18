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
  command = data['command']
  puts url, command
  if command == 'url'
    stdout, stderr, status = system("./process.sh #{url}")
    if status.success?
      stdout
    else
      "Error: #{stderr}"
    end
  elsif command == 'playlist'
    stdout, stderr, status = system("./process_playlist.sh #{url}")
    if status.success?
      stdout
    else
      "Error: #{stderr}"
    end
  end
end
