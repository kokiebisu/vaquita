require 'fileutils'
require 'open-uri'
require 'mini_magick'
require 'taglib'
require 'open3'
require 'streamio-ffmpeg'

FFMPEG.logger.level = Logger::ERROR

module Processor
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def process
      raise NotImplementedError, "You must implement the process method in #{self.name}"
    end

    def escape_for_shell(video_title)
      parts = video_title.split("'")
      escaped_title = parts.join("'\\''")
      escaped_title
    end

    def download_video(video_url, video_title, artist_name='', output_path='.')
      puts "Started download process with #{video_url} #{video_title} #{artist_name} #{output_path}..."
      output_file_pattern = File.join(output_path, "#{video_title}.%(ext)s")
      command = "yt-dlp -f bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4] -o #{output_file_pattern.shellescape} #{video_url.shellescape}"

      if system(command)
        puts "Download successful for #{video_title}"
        return video_title
      else
        puts "Download failed for #{video_title}"
        raise "Failed to execute download command."
      end
    end
  end
end

class VideoProcessor include Processor
  def self.process(url, video_title, artist_name, album_name, thumbnail_img_url, output_path)
    puts "Started processing the url with #{url} #{video_title} #{artist_name} #{album_name} #{thumbnail_img_url} #{output_path}"
    begin
      output_path = output_path.is_a?(Hash) ? output_path[:output_path] : output_path
      if album_name
        album_name.is_a?(String) ? album_name : album_name['content']
      else
        album_name = video_title
      end
      video_title = download_video(url, video_title, artist_name, output_path)
      convert_video_to_audio(video_title, output_path)
      cover_img_path = download_image(thumbnail_img_url, "#{output_path}/cover.jpg")
      attach_metadata(video_title, cover_img_path, artist_name, album_name, video_title, output_path)
      FileUtils.rm("#{output_path}/#{video_title}.mp4") if File.exist?("#{output_path}/#{video_title}.mp4")
      FileUtils.rm("#{output_path}/cover.jpg") if File.exist?("#{output_path}/cover.jpg")
    rescue => e
      puts "Error processing #{url}: #{e}"
      raise e
    end
  end
end

def convert_video_to_audio(video_title, output_path, input_format='mp4', output_format='mp3')
  begin
    source_path = File.join(output_path, "#{video_title}.#{input_format}")
    dest_path = File.join(output_path, "#{video_title}.#{output_format}")
    movie = FFMPEG::Movie.new(source_path)
    movie.transcode(dest_path, %W(-vn -acodec libmp3lame -q:a 2))
  rescue StandardError => e
    puts "Error converting video format: #{e}"
    raise e
  end
end

def download_image(image_url, output_path)
  begin
    URI.open(image_url) do |image|
      File.open(output_path, "wb") do |file|
        file.write(image.read)
      end
    end
    output_path
  rescue => e
    puts "Error downloading image from URL: #{image_url}, Error: #{e}"
    nil
  end
end

def capture_image(video_path, output_path)
  begin
    `ffmpeg -i #{video_path} -ss 00:01:00 -vframes 1 #{output_path}`
  rescue => e
    puts "Error capturing image: #{e}"
    raise e
  end
end

def attach_metadata(video_title, cover_img_path, artist_name, album_title, title, output_path)
  begin
    TagLib::MPEG::File.open("#{output_path}/#{video_title}.mp3") do |file|
      tag = file.id3v2_tag
      cover = TagLib::ID3v2::AttachedPictureFrame.new
      cover.mime_type = cover_img_path.end_with?('.gif') ? "image/gif" : "image/jpeg"
      cover.picture = File.open(cover_img_path, 'rb').read
      cover.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
      tag.add_frame(cover)
      tag.artist = artist_name.encode("UTF-8")
      tag.album = album_title.is_a?(Hash) ? album_title["content"] : album_title.encode("UTF-8")
      tag.title = title.encode("UTF-8")
      file.save
    end
  rescue => e
    puts "Error attaching emtadata: #{e}"
    raise e
  end
end
