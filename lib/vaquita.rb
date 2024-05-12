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
  opts.on("--output TYPE", ["video", "music"], "Specify 'url' for videos")
end.parse!

def main(options)
  if ['recommendation', 'music-playlist'].include?(options[:type])
    cookie = Utils.read_cookie_json
    path = Utils.get_desktop_folder
    if options[:type] == 'music-playlist'
      url = ARGV[0]
      result_data = process_music_playlist(cookie, url, path)
    elsif options[:type] == 'recommendation'
      result_data = process_quick_picks(cookie, path)
    end
  elsif options[:type] == 'url'
      url = ARGV[0]
    if options[':output'] == 'music'
      result_data = process_url(url)
    else
      result_data = process_video_url(url)
    end
  else
    raise ArgumentError, "Please specify --type with 'url', 'music-playlist' or 'recommendation'"
  end
  Utils.write_to_json_file(result_data)
end

main(options) if __FILE__ == $PROGRAM_NAME
