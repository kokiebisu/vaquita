require 'sinatra'
require 'json'
require 'logger'
require 'sidekiq'
require 'sidekiq/web'

require './lib/vaquita'
require './lib/vaquita/worker'
require './lib/vaquita/sidekiq/setup'

set :bind, '0.0.0.0'
set :logging, true

before do
  content_type :json
end

post '/process' do
  data = JSON.parse(request.body.read)
  command = data['command']
  output_type = data['outputType'] || 'audio'
  if command == 'recommendations' or command == 'trending'
    Worker.perform_async(command, output_type)
  else
    Worker.perform_async('url', output_type, data['url'])
  end
  { status: 'success' }.to_json
end
