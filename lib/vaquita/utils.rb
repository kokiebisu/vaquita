require 'pathname'

module Utils
  def self.get_base_path
    return Pathname.new('/usr/src/app/downloads')
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
      sanitized_words
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
    result
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

  def self.read_cookie_json()
    json = File.read('credentials.json')
    data = JSON.parse(json)
    data['cookie']
  end

  def self.parse_json_with_escaped_chars(json_string)
    begin
      cleaned_string = json_string.gsub('\\\\', '\\')
      parsed_string = cleaned_string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      JSON.parse(parsed_string)
    rescue JSON::ParserError => e
      puts "Error parsing JSON with escaped chars: #{e.message}"
      nil
    end
  end

  def self.parse_json(json_string)
    begin
      return JSON.parse(json_string)
    rescue JSON::ParserError => e
      puts "Error parsing JSON: #{e.message}"
      nil
    end
  end
end
