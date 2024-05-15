require 'bundler/setup'

require 'concurrent'
require 'fileutils'
require 'pathname'
require 'ruby-progressbar'
require 'optparse'

require_relative 'vaquita/processor'
require_relative 'vaquita/youtube/processor'
require_relative 'vaquita/youtube_music/processor'
require_relative 'vaquita/utils'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby lib/vaquita.rb --command [url|recommendations|trending] --output [VIDEO|AUDIO]"

  opts.on("--command COMMAND", ["url", "music-playlist", "recommendation"], "Specify 'url' for URLs or 'recommendation' for recommendations") do |command|
    options[:command] = command
  end

  opts.on("--output OUTPUT", ["video", "audio"], "Specify 'video' for videos or 'audio' for audio") do |output|
    options[:output] = output
  end
end.parse!

def main(options)
  cookie_value = Utils.read_cookie_json
  if ['recommendations', 'trending'].include?(options[:command])
    path = Utils.get_base_path
    if options[:command] == 'recommendations'
      process_quick_picks(cookie_value, path)
    elsif options[:type] == 'recommendation'
      # to be implemented...
      # process_trending(cookie, path)
    end
  elsif options[:command] == 'url'
      url = ARGV[0]
      process_url(cookie_value, url, options[:output])
  else
    raise ArgumentError, "Please specify --command with 'url', 'recommendations' or 'trending'"
  end
end

main(options) if __FILE__ == $PROGRAM_NAME
