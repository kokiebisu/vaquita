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
  opts.banner = "Usage: ruby lib/vaquita.rb --type [url|recommendation] [URL|COOKIE_VALUE]"
  opts.on("--type TYPE", ["url", "music-playlist", "recommendation"], "Specify 'url' for URLs or 'recommendation' for recommendations") do |type|
    options[:type] = type
  end
  opts.on("--output TYPE", ["video", "music"], "Specify 'url' for videos") do |output|
    options[:output] = output
  end
end.parse!

def main(options)
  if ['recommendation', 'music-playlist'].include?(options[:type])
    cookie = Utils.read_cookie_json
    path = Utils.get_base_path
    if options[:type] == 'music-playlist'
      url = ARGV[0]
      process_music_playlist(cookie, url, path)
    elsif options[:type] == 'recommendation'
      process_quick_picks(cookie, path)
    end
  elsif options[:type] == 'url'
      url = ARGV[0]
      process_url(url, options[:output])
  else
    raise ArgumentError, "Please specify --type with 'url', 'music-playlist' or 'recommendation'"
  end
end

main(options) if __FILE__ == $PROGRAM_NAME
