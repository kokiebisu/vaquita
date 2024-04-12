require 'concurrent'
require 'fileutils'
require 'pathname'
require 'thwait'
require 'tqdm'
require 'ruby-progressbar'

require_relative 'lib/extractor'
require_relative 'lib/processor'
require_relative 'lib/utils'

def process_song(url, base_path)
    begin
      song_title, artist_name, album_name, thumbnail_img_url = SongInfoExtractor.extract(url)
      VideoProcessor.process(url, song_title, artist_name, album_name, thumbnail_img_url, base_path)
      true
    rescue StandardError => e
      puts "Error processing #{url}: #{e}"
      false
    end
end

# def process_playlist(urls, base_path)
#     max_workers = 4
#     pool = Concurrent::FixedThreadPool.new(max_workers)
#     futures = urls.map do |url|
#       Concurrent::Future.execute(executor: pool) { process_song(url, base_path) }
#     end

#     Tqdm::ProgressBar.wrap(futures, desc: "Processing Videos", total: urls.length, unit: 'video') do |future|
#       result = future.value!
#     end

#     pool.shutdown
#     pool.wait_for_termination
# end

def process_playlist(urls, base_path)
  max_workers = 4
  pool = Concurrent::FixedThreadPool.new(max_workers)
  progressbar = ProgressBar.create(title: "Processing Videos", total: urls.length, format: '%a |%b>>%i| %p%% %t')

  futures = urls.map do |url|
    Concurrent::Future.execute(executor: pool) do
      result = process_song(url, base_path)
      progressbar.increment  # Update the progress bar after each task completes
      result
    end
  end

  # Wait for all futures to complete
  futures.each(&:value!)

  pool.shutdown
  pool.wait_for_termination
  progressbar.finish
end

def main
    url = ARGV[0]
    path = Utils.get_desktop_folder
    if url.include?('playlist')
      album_name, video_urls = PlaylistInfoExtractor.extract(url)
      output_path = Pathname.new("#{path}/#{album_name}")
      FileUtils.mkdir(output_path)
      process_playlist(video_urls, output_path)
    else
      song_title, artist_name, album_name, thumbnail_img_url = SongInfoExtractor.extract(url)
      song_title = song_title.tr('/', '-')
      VideoProcessor.process(url, song_title, artist_name, album_name, thumbnail_img_url, output_path: Pathname.new(path)[:output_path])
      output_path = Pathname.new("#{path}/#{song_title}.mp3")
    end
    File.open("output_dir.txt", "w") { |file| file.write(output_path.to_s) }
end

main if __FILE__ == $PROGRAM_NAME
