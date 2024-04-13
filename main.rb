require 'concurrent'
require 'fileutils'
require 'pathname'
require 'thwait'
require 'tqdm'
require 'ruby-progressbar'

require_relative 'lib/extractor'
require_relative 'lib/processor'
require_relative 'lib/utils'

def process_song(song_url, base_path)
  song_title, artist_name, album_name, thumbnail_img_url = SongInfoExtractor.extract(song_url)
  song_title = song_title.tr('/', '-') if song_title
  VideoProcessor.process(song_url, song_title, artist_name, album_name, thumbnail_img_url, output_path: base_path)
  output_path = Pathname.new("#{base_path}/#{song_title}.mp3")
  return output_path
end

def process_playlist(playlist_url, base_path)
  album_name, song_urls = PlaylistInfoExtractor.extract(playlist_url)
  output_path = Pathname.new("#{base_path}/#{album_name}")
  FileUtils.mkdir(output_path)

  progressbar = ProgressBar.create(title: "Processing Playlist", total: song_urls.length, format: '%a |%b>>%i| %p%% %t')

  song_urls.each do |song_url|
    result = process_song(song_url, output_path)
    progressbar.increment
  end

  progressbar.finish
  return output_path
end

def process_release(release_url, base_path)
  artist_name, playlist_urls = ReleasesExtractor.extract(release_url)
  output_path = Pathname.new("#{base_path}/#{artist_name}")
  FileUtils.mkdir_p(output_path)

  max_threads = 4
  pool = Concurrent::FixedThreadPool.new(max_threads)

  playlist_urls.each do |playlist_url|
    pool.post do
      begin
        process_playlist(playlist_url, output_path)
      rescue => e
        puts "Error in processing playlist: #{playlist_url}, Error: #{e}"
      end
    end
  end

  pool.shutdown
  pool.wait_for_termination

  return output_path
end

def main
    url = ARGV[0]
    path = Utils.get_desktop_folder
    if url.include?('releases')
      output_path = process_release(url, path)
    elsif url.include?('playlist')
      output_path = process_playlist(url, path)
    else
      output_path = process_song(url, path)
    end
    File.open("output_dir.txt", "w") { |file| file.write(output_path.to_s) }
end

main if __FILE__ == $PROGRAM_NAME
