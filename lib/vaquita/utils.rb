require 'pathname'

module Utils
  def self.get_desktop_folder
    home_dir = Pathname.new(Dir.home)
    desktop_folder = home_dir.join('Desktop')
    return desktop_folder
  end

  def self.sanitize_filename(filename, extra_keywords = [])
    begin
      excluded_keywords = exclude_keywords(filename, extra_keywords)
      if excluded_keywords.include?('-')
        sanitized_words = excluded_keywords.split('-').map(&:strip).map(&:capitalize)
      elsif excluded_keywords.include?('/')
        sanitized_words = excluded_keywords.split('/').map(&:strip).map(&:capitalize)
      else
        sanitized_words = excluded_keywords.split.map(&:strip).map(&:capitalize)
      end
    rescue => e
      puts "Error sanitizing filename: #{e}"
      raise e
    end
  end

  def self.exclude_keywords(filename, extra_keywords)
    keywords_to_exclude = ['performance', 'official', 'video', 'music',
                           'video', 'lyrics', 'audio', 'hd', 'hq',
                           'remix', '[music', 'video]'] + extra_keywords
    result = filename.split.select do |word|
      !keywords_to_exclude.any? { |keyword| word.downcase.include?(keyword) }
    end
  end

  def self.download_image(image_url, destination_path)
    begin
      URI.open(image_url) do |image|
        File.open(destination_path, 'wb') do |file|
          file.write(image.read)
        end
      end
      puts "Image downloaded successfully to #{destination_path}"
    rescue StandardError => e
      puts "Failed to download image: #{e.message}"
    end
  end
end
