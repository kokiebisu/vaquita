require 'sinatra'

require './lib/vaquita'

before do
  content_type :json
end

post '/process' do
  data = JSON.parse(request.body.read)
  url = data['url']
  type = data['type']

  script = type == 'url' ? "./process.sh" : "./process_playlist.sh"
  system("#{script} #{url}")
end
