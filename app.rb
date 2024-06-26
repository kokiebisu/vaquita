require 'sinatra'
require 'json'
require 'logger'

set :bind, '0.0.0.0'
set :logging, true

require './lib/vaquita'

before do
  content_type :json
end

post '/process' do
  data = JSON.parse(request.body.read)
  if data['command'] == 'recommendations' or data['command'] == 'trending'
    script = "ruby ./lib/vaquita.rb --command #{data['command']} --output #{data['outputType']}"
  else
    output_type = 'audio'
    if data['outputType']
      output_type = data['outputType']
    end
    script = "ruby ./lib/vaquita.rb --command url #{data['url']} --output #{output_type}"
  end
  system(script)
  { status: 'success' }.to_json
end
