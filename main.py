import argparse
import json
import os
import requests
import re
import urllib

from bs4 import BeautifulSoup
from pytube import YouTube
from pydub import AudioSegment
import eyed3


def main():
    parser = argparse.ArgumentParser(description='Pass in the url of the image'
                                     'in which you want to download')
    parser.add_argument(
        '--artist', required=True, help='Artist')
    parser.add_argument(
        '--album', required=True, help='Album')
    args = parser.parse_args()

    search_query = generate_search_query(artist_name=args.artist,
                                         album_name=args.album)
    thumbnail_img_url, artist_name, album_title = get_metadata_info(
        search_query)
    for video_url in ['https://www.youtube.com/watch?v=23hrIMQqzSk&list=PL117GFO3o4uiwzDrx4TkdViA9k_BDL_lI&index=4']:
        video_title = download_video(video_url=video_url)
        mp3_file_path = convert_video_format(
            video_title, video_filename=f'{video_title}.mp4')
        attach_metadata(mp3_file_path,
                        thumbnail_img_url, artist_name, album_title, 
                        video_title)


def sanitize_filename(filename):
    return filename.replace(' ', '_')


def generate_search_query(artist_name, album_name):
    return f'{artist_name.lower().replace("&", "")}+{album_name.lower()}'\
        .replace(' ', '+')


def get_metadata_info(search_query):
    base_url = 'https://www.youtube.com/results'
    params = {'search_query': search_query}
    try:
        response = requests.get(base_url, params=params)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')

        script_tags = soup.find_all('script')
        for script_tag in script_tags:
            if 'ytInitialData' in script_tag.text:
                script_content = script_tag.get_text()
                match = re.search(r'var\s+ytInitialData\s*=\s*({.*?});', 
                                  script_content)

                if match:
                    yt_initial_data_str = match.group(1)
                    data = json.loads(yt_initial_data_str)
                    card_info = (
                        data['contents']['twoColumnSearchResultsRenderer']
                        ['secondaryContents']
                        ['secondarySearchContainerRenderer']['contents']
                        [0]['universalWatchCardRenderer']
                    )
                    album_title = (
                        card_info['header']['watchCardRichHeaderRenderer']
                        ['title']['simpleText']
                    )
                    _, artist_name = map(str.strip, card_info['header']
                                         ['watchCardRichHeaderRenderer']
                                         ['subtitle']['simpleText'].split(
                                             '•', 1))
                    thumbnail_img_url = (
                        card_info['callToAction']['watchCardHeroVideoRenderer']
                        ['heroImage']['singleHeroImageRenderer']
                        ['thumbnail']['thumbnails'][0]['url']
                    )
                    return thumbnail_img_url, artist_name, album_title

    except Exception as e:
        print(f"Error: {e}")
        return None


def attach_metadata(
        mp3_file, thumbnail_img_url, artist_name, album_title, title):
    audiofile = eyed3.load(mp3_file)
    response = urllib.request.urlopen(thumbnail_img_url)
    imagedata = response.read()
    audiofile.tag.artist = artist_name
    audiofile.tag.album_artist = artist_name
    audiofile.tag.title = title
    audiofile.tag.album = album_title
    audiofile.tag.images.set(3, imagedata, "image/jpeg", u"cover")
    audiofile.tag.save()


def download_video(video_url):
    yt = YouTube(video_url)
    video_stream = yt.streams.get_highest_resolution()
    video_title = yt.title
    video_stream.download()
    return video_title


def convert_video_format(video_title, video_filename, input_format='mp4', 
                         output_format='mp3'):
    sanitized_filename = sanitize_filename(video_filename)
    os.rename(video_filename, sanitized_filename)
    audio = AudioSegment.from_file(sanitized_filename, format=input_format)
    audio_file_path = f'{video_title}.{output_format}'
    audio.export(audio_file_path, codec=output_format)
    os.remove(sanitized_filename)
    return audio_file_path


if __name__ == '__main__':
    main()
