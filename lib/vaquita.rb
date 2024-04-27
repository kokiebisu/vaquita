require 'bundler/setup'
require 'tarsier'

require 'concurrent'
require 'fileutils'
require 'pathname'
require 'ruby-progressbar'
require 'tarsier'
require 'optparse'

require_relative 'vaquita/extractor'
require_relative 'vaquita/processor'
require_relative 'vaquita/utils'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby lib/vaquita.rb --type [url|recommendation] [URL|COOKIE_VALUE]"
  opts.on("--type TYPE", ["url", "music-playlist", "recommendation"], "Specify 'url' for URLs or 'recommendation' for recommendations") do |type|
    options[:type] = type
  end
end.parse!

def read_cookie_json()
  json = File.read('credentials.json')
  data = JSON.parse(json)
  data['cookie']
end

def process_recommendation(cookie_value, path)
  urls = Tarsier.extract_recommendations(cookie_value)
  progressbar = ProgressBar.create(title: "Processing Song", total: urls.length, format: '%a |%b>>%i| %p%% %t')
  output_path = Pathname.new("#{path}/recommendations")
  urls.each do |url|
    process_song(url, path, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  return output_path
end

def process_music_playlist(cookie_value, url, path)
  cover_img_url, playlist_name, urls = Tarsier.extract_playlist(cookie_value, url)
  # download the cover_img_url to cover_img_path
  output_path = Pathname.new("#{path}/#{playlist_name}")
  progressbar = ProgressBar.create(title: "Processing Song", total: urls.length, format: '%a |%b>>%i| %p%% %t')
  urls.each do |url|
    process_song(url, output_path, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  cover_img_path = Pathname.new("#{path}/#{playlist_name}/playlist_cover.jpg")
  # Download the cover image to the specified path
  Utils.download_image(cover_img_url, cover_img_path)
  puts "COVER IMAGE PATH: #{cover_img_path}"
  return cover_img_path, playlist_name, output_path
end

def process_song(song_url, base_path, progressbar)
  begin
    song_title, artist_name, album_name, thumbnail_img_url = SongInfoExtractor.extract(song_url)
    puts "Extracted song info: #{song_title} #{artist_name} #{album_name} #{thumbnail_img_url}"
    song_title = song_title.tr('/', '-') if song_title
    VideoProcessor.process(song_url, song_title, artist_name, album_name, thumbnail_img_url, output_path: base_path)
    output_path = Pathname.new("#{base_path}/#{song_title}.mp3")
    progressbar.increment
    return output_path
  rescue => e
    puts "Error processing song #{e}"
  end
end

def process_playlist(playlist_url, base_path, progressbar=nil)
  album_name, song_urls = PlaylistInfoExtractor.extract(playlist_url)
  output_path = Pathname.new("#{base_path}/#{album_name}")
  FileUtils.mkdir(output_path)
  progressbar ||= ProgressBar.create(title: "Processing Playlist", total: song_urls.length, format: '%a |%b>>%i| %p%% %t')
  song_urls.each do |song_url|
    result = process_song(song_url, output_path, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  return output_path
end

def process_release(release_url, base_path)
  artist_name, playlist_urls = ReleasesExtractor.extract(release_url)
  output_path = Pathname.new("#{base_path}/#{artist_name}")
  FileUtils.mkdir_p(output_path)
  progressbar = ProgressBar.create(title: "Processing Release", total: playlist_urls.length, format: '%a |%b>>%i| %p%% %t')
  max_threads = 4
  pool = Concurrent::FixedThreadPool.new(max_threads)
  playlist_urls.each do |playlist_url|
    pool.post do
      begin
        process_playlist(playlist_url, output_path, progressbar)
      rescue => e
        puts "Error in processing playlist: #{playlist_url}, Error: #{e}"
      end
    end
  end
  pool.shutdown
  pool.wait_for_termination
  progressbar.finish
  return output_path
end

def process_url(url)
  path = Utils.get_desktop_folder
  if url.include?('releases')
    output_path = process_release(url, path)
  elsif url.include?('playlist')
    output_path = process_playlist(url, path)
  else
    progressbar = ProgressBar.create(title: "Processing Song", total: 1, format: '%a |%b>>%i| %p%% %t')
    output_path = process_song(url, path, progressbar)
    progressbar.finish
  end
  return output_path
end

def main(options)
  if options[:type] == 'recommendation'
    path = Utils.get_desktop_folder
    cookie = read_cookie_json()
    path = Utils.get_desktop_folder
    output_path = process_recommendation(cookie, path)
    File.open("output_dir.txt", "w") { |file| file.write(output_path.to_s) }
  elsif options[:type] == 'music-playlist'
    url = ARGV[0]
    path = Utils.get_desktop_folder
    cookie = read_cookie_json()
    path = Utils.get_desktop_folder
    cover_img_url, playlist_name, output_path = process_music_playlist(cookie, url, path)
    File.open("playlist_name_path.txt", "w") { |file| file.write(playlist_name.to_s) }
    File.open("playlist_cover_img_url_path.txt", "w") { |file| file.write(cover_img_url.to_s) }
    File.open("resource_path.txt", "w") { |file| file.write(output_path.to_s) }
  elsif options[:type] == 'url'
    url = ARGV[0]
    output_path = process_url(url)
    File.open("output_dir.txt", "w") { |file| file.write(output_path.to_s) }
  else
    raise ArgumentError, "Please specify --type with 'url' or 'recommendation'"
  end
end

main(options) if __FILE__ == $PROGRAM_NAME
