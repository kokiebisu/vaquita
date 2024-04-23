require 'sinatra'

require './lib/vaquita'

before do
  content_type :json
end

post '/process' do
  data = JSON.parse(request.body.read)
  url = data['url']
  type = data['type']
  puts url, type

  script = type == 'url' ? "./process.sh" : "./process_playlist.sh"

  stdout, stderr, status = Open3.capture3("#{script} #{url}")
  if status.success?
    stdout
  else
    "Error: #{stderr}"
  end
end
