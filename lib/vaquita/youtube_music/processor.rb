require 'pathname'

require_relative 'scraper'

def process_quick_picks(cookie_value, path)
  urls = YoutubeMusicScraper.new(cookie_value, 'https://music.youtube.com').scrape_quick_picks
  progressbar = ProgressBar.create(title: "Processing Song", total: urls.length, format: '%a |%b>>%i| %p%% %t')
  output_path = Pathname.new("#{path}/recommendations")
  urls.each do |url|
    process_song(url, path, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  {
    outputPath: output_path.to_s
  }
end

def process_music_playlist(cookie_value, url, path)
  scraper = YoutubeMusicScraper.new(cookie_value, url)
  cover_img_url, playlist_name = scraper.scrape_playlist_metadata
  urls = scraper.scrape_playlist_songs
  output_path = Pathname.new("#{path}/#{playlist_name}/songs")
  progressbar = ProgressBar.create(title: "Processing Song", total: urls.length, format: '%a |%b>>%i| %p%% %t')
  urls.each do |url|
    process_song(url, output_path, progressbar)
  end
  progressbar.finish unless progressbar.finished?
  cover_img_path = Pathname.new("#{path}/#{playlist_name}/playlist_cover.jpg")
  Utils.download_image(cover_img_url, cover_img_path)
  {
    coverImgPath: cover_img_path.to_s,
    playlistName: playlist_name,
    outputPath: output_path.to_s
  }
end
