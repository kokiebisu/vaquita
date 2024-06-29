require 'nokogiri'
require 'json'

require_relative '../utils'
require_relative '../request'

class YoutubeMusicScraper
  def initialize(cookie, url)
    uri = URI(url)
    request_obj = create_request_obj(uri, cookie)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(request_obj)
    @url = url
    @doc = Nokogiri::HTML(response.body.force_encoding('UTF-8'))
    @data = get_initial_data
  end

  def scrape_quick_picks
    endpoints = []
    data = @data['contents']['singleColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'][0]['musicCarouselShelfRenderer']['contents']
    data.each do |item|
      if item['musicResponsiveListItemRenderer']
        video_id = item['musicResponsiveListItemRenderer']['overlay']['musicItemThumbnailOverlayRenderer']['content']['musicPlayButtonRenderer']['playNavigationEndpoint']['watchEndpoint']['videoId'] rescue nil
        endpoints.push("https://www.youtube.com/watch?v=#{video_id}") if video_id
      end
    end
    return endpoints
  end

  def scrape_playlist_songs
    endpoints = []
    contents = @data['contents']
    if contents['singleColumnBrowseResultsRenderer']
      data = contents['singleColumnBrowseResultsRenderer']
      if data['secondaryContents']
        data = data['secondaryContents']['sectionListRenderer']['contents'][0]['musicPlaylistShelfRenderer']['contents']
      elsif data['tabs']
        data = data['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents']
      end
    elsif contents['twoColumnBrowseResultsRenderer']
      data = contents['twoColumnBrowseResultsRenderer']['secondaryContents']['sectionListRenderer']['contents'][0]
      # when it is a playlist
      if data['musicPlaylistShelfRenderer']
        data = data['musicPlaylistShelfRenderer']['contents']
      # when it is an album
      elsif data['musicShelfRenderer']
        data = data['musicShelfRenderer']['contents']
      end
    end
    data.each do |item|
      if item['musicShelfRenderer']
        item['musicShelfRenderer']['contents'].each do |video|
          video_id = video['musicResponsiveListItemRenderer']['overlay']['musicItemThumbnailOverlayRenderer']['content']['musicPlayButtonRenderer']['playNavigationEndpoint']['watchEndpoint']['videoId'] rescue nil
          endpoints.push("https://www.youtube.com/watch?v=#{video_id}") if video_id
        end
      end
      if item['musicPlaylistShelfRenderer']
        item['musicPlaylistShelfRenderer']['contents'].each do |video|
          video_id = video['musicResponsiveListItemRenderer']['overlay']['musicItemThumbnailOverlayRenderer']['content']['musicPlayButtonRenderer']['playNavigationEndpoint']['watchEndpoint']['videoId'] rescue nil
          endpoints.push("https://www.youtube.com/watch?v=#{video_id}") if video_id
        end
      end
      if item['musicResponsiveListItemRenderer']
        video_id = item['musicResponsiveListItemRenderer']['menu']['menuRenderer']['topLevelButtons'][0]['likeButtonRenderer']['target']['videoId']
        endpoints.push("https://www.youtube.com/watch?v=#{video_id}") if video_id
      end
    end
    return endpoints
  end

  def scrape_album_or_playlist
    if @data['header']
      @data['header']['musicDetailHeaderRenderer']['subtitle']['runs'][0]['text'].downcase
    end
    @data['contents']['twoColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'][0]['musicResponsiveHeaderRenderer']['subtitle']['runs'][0]['text'].downcase
  end

  def scrape_playlist_metadata
    contents = @data['contents']
    if contents['singleColumnBrowseResultsRenderer']
      data = contents['singleColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'][0]
      if data['musicResponsiveHeaderRenderer']
        playlist_cover_img_url = data['musicResponsiveHeaderRenderer']['thumbnail']['musicThumbnailRenderer']['thumbnail']['thumbnails'][3]['url']
        playlist_name = data[0]['musicResponsiveHeaderRenderer']['title']['runs'][0]['text']
      else
        playlist_cover_img_url = @data['header']['musicDetailHeaderRenderer']['thumbnail']['croppedSquareThumbnailRenderer']['thumbnail']['thumbnails'][-1]['url']
        playlist_name = @data['header']['musicDetailHeaderRenderer']['title']['runs'][0]['text']
      end
    elsif contents['twoColumnBrowseResultsRenderer']
      data = contents['twoColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents']
      playlist_cover_img_url = data[0]['musicResponsiveHeaderRenderer']['thumbnail']['musicThumbnailRenderer']['thumbnail']['thumbnails'][-1]['url']
    end
    if playlist_name == ""
      raise Exception("playlist name is empty")
    end
    return playlist_cover_img_url, playlist_name
  end

  private

  def get_initial_data
    script_tag = @doc.xpath("//script[contains(text(), 'initialData')]").first
    raise "initialData not found in the provided HTML." unless script_tag

    script_content = script_tag.content
    all_push_matches = script_content.scan(/initialData\.push\((\{.*?\}\);)/m).map(&:first)
    raise "Not enough initialData.push calls found." unless all_push_matches.size >= 2

    second_push = all_push_matches[1]
    escaped_string = second_push.match(/data:\s*'((?:\\x..|[^'])*)'/)[1]
    initial_data = escaped_string.gsub(/\\x([0-9A-Fa-f]{2})/) { |match|
      [$1].pack('H*')
    }
    Utils.parse_json_with_escaped_chars(initial_data)
  end
end
