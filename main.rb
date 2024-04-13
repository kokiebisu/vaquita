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

  max_workers = 4
  pool = Concurrent::FixedThreadPool.new(max_workers)
  progressbar = ProgressBar.create(title: "Processing Playlist", total: song_urls.length, format: '%a |%b>>%i| %p%% %t')

  futures = song_urls.map do |song_url|
    Concurrent::Future.execute(executor: pool) do
      result = process_song(song_url, output_path)
      progressbar.increment
      result
    end
  end

  futures.each(&:value!)

  pool.shutdown
  pool.wait_for_termination
  progressbar.finish

  return output_path
end

def process_release(release_url, base_path)
  artist_name, playlist_urls = ReleasesExtractor.extract(release_url)
  output_path = Pathname.new("#{base_path}/#{artist_name}")
  FileUtils.mkdir(output_path)
  playlist_urls.each do |playlist_url|
    process_playlist(playlist_url, output_path)
  end
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
