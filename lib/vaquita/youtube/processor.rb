require 'pathname'

require_relative 'scraper'

def process_media(url, base_path, output_mode, with_tor, progressbar)
  puts "Processing media with url: #{url}, base_path: #{base_path}, output_mode: #{output_mode}, with_tor: #{with_tor}, progressbar: #{progressbar}"
  begin
    scraper = YoutubeScraper.new(url)
    if output_mode == 'audio'
      song_title, artist_name, album_name, thumbnail_img_url = scraper.scrape_song
      puts "Extracted song info: #{song_title} #{artist_name} #{album_name} #{thumbnail_img_url}"
      song_title = song_title.tr('/', '-') if song_title
      MusicProcessor.retrieve(url, song_title, artist_name, album_name, thumbnail_img_url, with_tor, base_path)
      output_path = Pathname.new("#{base_path}/#{song_title}.mp3")
    elsif output_mode == 'video'
      title = scraper.scrape_video
      puts "Extracted video info: #{title}"
      VideoProcessor.retrieve(url, title, with_tor, base_path)
      video_title = title.tr('/', '-')
      output_path = Pathname.new("#{base_path}/#{video_title}.mp4")
    end
    progressbar.increment
    output_path
  rescue => e
    puts "Error processing media #{e}"
  end
end

def process_playlist(playlist_url, base_path, output_mode, with_tor, progressbar=nil)
  playlist_name, urls = YoutubeScraper.new(playlist_url).scrape_playlist(output_mode)
  output_path = Pathname.new("#{base_path}/#{playlist_name}")
  FileUtils.mkdir_p(output_path)
  progressbar ||= ProgressBar.create(title: "Processing Playlist", total: urls.length, format: '%a |%b>>%i| %p%% %t')
  urls.each do |url|
    process_media(url, output_path, output_mode, with_tor, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  return output_path
end

def process_release_albums(release_url, base_path, with_tor)
  artist_name, playlist_urls = YoutubeScraper.new(release_url).scrape_release
  output_path = Pathname.new("#{base_path}/#{artist_name}")
  FileUtils.mkdir_p(output_path)
  progressbar = ProgressBar.create(title: "Processing Release", total: playlist_urls.length, format: '%a |%b>>%i| %p%% %t')
  max_threads = 4
  pool = Concurrent::FixedThreadPool.new(max_threads)
  playlist_urls.each do |playlist_url|
    pool.post do
      begin
        process_playlist(playlist_url, output_path, 'audio', with_tor, progressbar)
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

def process_videos(videos_url, with_tor, base_path)
  channel_name, video_urls = YoutubeScraper.new(videos_url).scrape_videos
  output_path = Pathname.new("#{base_path}/#{channel_name}")
  FileUtils.mkdir_p(output_path)
  progressbar ||= ProgressBar.create(title: "Processing Videos", total: video_urls.length, format: '%a |%b>>%i| %p%% %t')
  video_urls.each do |url|
    process_media(url, output_path, 'video', with_tor, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  return output_path
end

def process_url(cookie_value, url, output_mode, with_tor)
  path = Utils.get_base_path

  begin
    uri = URI.parse(url)
    domain = uri.host

    case domain
    when 'www.youtube.com'
      process_youtube(path, url, output_mode, with_tor)
    when 'music.youtube.com'
      process_youtube_music(cookie_value, url, path, with_tor)
    else
      puts "Unsupported domain: #{domain}"
      raise ArgumentError, "Unsupported domain: #{domain}"
    end
  rescue URI::InvalidURIError
    puts "Invalid URL: #{url}"
    raise ArgumentError, "Invalid URL: #{url}"
  end
end

def process_youtube(path, url, output_mode, with_tor)
  if url.include?('releases')
    process_release_albums(url, path, with_tor)
  elsif url.include?('playlist')
    process_playlist(url, path, output_mode, with_tor)
  elsif url.include?('watch')
    progressbar = ProgressBar.create(title: "Processing Song", total: 1, format: '%a |%b>>%i| %p%% %t')
    process_media(url, path, output_mode, with_tor, progressbar)
    progressbar.finish
  else
    raise "Cannot identify the type!"
  end
end
