require 'net/http'
require 'nokogiri'
require 'json'

require_relative '../utils'

class YoutubeScraper
  def initialize(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    raise "HTTP Error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    @url = url
    @doc = Nokogiri::HTML(response.body.force_encoding('UTF-8'))
    @data = get_initial_data
  end

  def scrape_videos
    video_items = @data.dig('contents', 'twoColumnBrowseResultsRenderer', 'tabs', 1, 'tabRenderer', 'content', 'richGridRenderer', 'contents')
    urls = video_items.map do |item|
      video_id = item.dig('richItemRenderer', 'content', 'videoRenderer', 'videoId')
      if video_id
        "https://www.youtube.com/watch?v=#{video_id}"
      end
    end
    channel_name = @data.dig('metadata', 'channelMetadataRenderer', 'title')
    return channel_name, urls
  end

  def scrape_video
    @data.dig('playerOverlays', 'playerOverlayRenderer', 'videoDetails', 'playerOverlayVideoDetailsRenderer', 'title', 'simpleText')
  end

  def scrape_releases
    artist_name = @data.dig('contents', 'twoColumnBrowseResultsRenderer', 'tabs', 4, 'tabRenderer', 'content', 'richGridRenderer', 'contents', 0, 'richItemRenderer', 'content', 'playlistRenderer', 'shortBylineText', 'runs', 0, 'text')
    releases = @data.dig('contents', 'twoColumnBrowseResultsRenderer', 'tabs', 4, 'tabRenderer', 'content', 'richGridRenderer', 'contents')
    playlist_ids = releases.map do |release|
      if release.dig('richItemRenderer')
        "https://www.youtube.com/playlist?list=" + release.dig('richItemRenderer', 'content', 'playlistRenderer', 'playlistId')
      end
    end.compact
    return artist_name, playlist_ids
  rescue => e
    puts "Error scraping the release: #{e}"
  end

  def scrape_playlist(output_mode)
    metadata = @data.dig('metadata', 'playlistMetadataRenderer')
    playlist_name = metadata.dig(output_mode == 'audio' ? 'albumName' : 'title')
    urls = @data.dig('contents', 'twoColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'itemSectionRenderer', 'contents', 0, 'playlistVideoListRenderer', 'contents').select { |content| content.key?('playlistVideoRenderer') }.map { |vid| "https://www.youtube.com/watch?v=" + vid.dig('playlistVideoRenderer', 'navigationEndpoint', 'watchEndpoint', 'videoId') }
    return playlist_name, urls
  rescue => e
    puts "Error scraping the playlist: #{e}"
  end

  def scrape_song
    @data['engagementPanels'].each do |panel|
      if panel['engagementPanelSectionListRenderer']
        item_data = panel['engagementPanelSectionListRenderer']&.dig('content', 'structuredDescriptionContentRenderer', 'items')
        if item_data and item_data.is_a?(Array)
          item_data.each do |card|
            if card['horizontalCardListRenderer']
              card_data = card['horizontalCardListRenderer']['cards']
              card_data.each do |card_item|
                if card_item['videoAttributeViewModel']
                  data = card_item['videoAttributeViewModel']
                  song_title = data['title'].encode('UTF-8')
                  artist_name = data['subtitle'].encode('UTF-8')
                  album_name = data['secondarySubtitle']
                  cover_img_url = data['image']['sources'][0]['url']
                  return song_title, artist_name, album_name, cover_img_url
                end
              end
            end
          end
          item_data.each do |card|
            if card['videoDescriptionHeaderRenderer']
              card_data = card['videoDescriptionHeaderRenderer']
              song_title = card_data['title']['runs'][0]['text']
              artist_name = card_data['channel']['simpleText']
              album_name = song_title
              return song_title, artist_name, album_name, @url
            end
          end
        end
      end
    end
  rescue => e
    puts "Error scraping song: #{e}"
  end

  private

  def get_initial_data
    script_tags = @doc.css('script')
    script_tags.each do |script_tag|
      match = script_tag.content.match(/var\s+ytInitialData\s*=\s*(\{.*?\});/)
      if match
        return Utils.parse_json(match[1])
      end
    end
  end
end
