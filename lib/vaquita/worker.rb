require 'sidekiq'

class Worker
  include Sidekiq::Worker

  def perform(command, output_type, url = nil)
    if command == 'recommendations' || command == 'trending'
      script = "ruby ./lib/vaquita.rb --command #{command} --output #{output_type}"
    else
      script = "ruby ./lib/vaquita.rb --command #{command} --output #{output_type} #{url}"
    end
    system(script)
  end
end
