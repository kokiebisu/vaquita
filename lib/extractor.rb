require 'net/http'
require 'nokogiri'
require 'json'

module InfoExtractor
  def extract(video_url)
    raise NotImplementedError, "#{self.class.name}##{__method__} is an abstract method."
  end
end

class PlaylistInfoExtractor extend InfoExtractor
  def self.extract(video_url)
    uri = URI(video_url)
    response = Net::HTTP.get_response(uri)
    raise "HTTP Error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    soup = Nokogiri::HTML(response.body.force_encoding('UTF-8'))
    script_tags = soup.css('script')
    script_tags.each do |script_tag|
      if script_tag.content.include?('ytInitialData')
        match = script_tag.content.match(/var\s+ytInitialData\s*=\s*(\{.*?\});/)
        if match
          yt_initial_data = JSON.parse(match[1])
          album_name = yt_initial_data.dig('metadata', 'playlistMetadataRenderer', 'albumName')
          song_urls = yt_initial_data.dig('contents', 'twoColumnBrowseResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents', 0, 'itemSectionRenderer', 'contents', 0, 'playlistVideoListRenderer', 'contents').select { |content| content.key?('playlistVideoRenderer') }.map { |vid| "https://www.youtube.com" + vid.dig('playlistVideoRenderer', 'navigationEndpoint', 'commandMetadata', 'webCommandMetadata', 'url') }
          return album_name, song_urls
        end
      end
    end
    raise "Playlist not found"
  rescue => e
    puts "Error extracting Youtube playlist info: #{e}"
    nil
  end
end


class SongInfoExtractor extend InfoExtractor
  def self.extract(video_url)
    uri = URI(video_url)
    response = Net::HTTP.get_response(uri)
    raise "HTTP ERROR: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    soup = Nokogiri::HTML(response.body.force_encoding('UTF-8'))
    script_tags = soup.css('script')
    script_tags.each do |script_tag|
      if script_tag.content.include?('ytInitialData')
        match = script_tag.content.match(/var\s+ytInitialData\s*=\s*(\{.*?\});/)
        if match
          yt_initial_data = JSON.parse(match[1])
          yt_initial_data['engagementPanels'].each do |panel|

            if panel['engagementPanelSectionListRenderer']
              item_data = panel['engagementPanelSectionListRenderer']&.dig('content', 'structuredDescriptionContentRenderer', 'items')
              if item_data
                item_data.each do |card|
                  if card['horizontalCardListRenderer']
                    return extract_song(card)
                  end
                end
                item_data.each do |card|
                  if card['videoDescriptionHeaderRenderer']
                    return extract_video(card, video_url)
                  end
                end
              end
            end
          end
        end
      end
    end
    raise "Not found"
    rescue => e
      puts "Error extracting youtube song info: #{e}"
    nil
  end

  def self.extract_song(card)
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

  def self.extract_video(card, video_url)
    card_data = card['videoDescriptionHeaderRenderer']
    song_title = card_data['title']['runs'][0]['text']
    artist_name = card_data['channel']['simpleText']
    album_name = song_title
    return song_title, artist_name, album_name, video_url
  end
end
