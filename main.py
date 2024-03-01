import json
import os
import requests
import re
import urllib

from bs4 import BeautifulSoup
from pytube import YouTube
from pydub import AudioSegment
import concurrent.futures
import eyed3
from tqdm import tqdm

eyed3.log.setLevel("ERROR")


def main():
    # playlist_url = input("Provide the Youtube album playlist URL\n")
    # album = input("What is the name of the album?\n")
    playlist_url = 'https://www.youtube.com/playlist?list=OLAK5uy_maBlY_Q9yOjOWP9EyCnbzTsHZ2zR55w9E'

    artist_name, album_title, thumbnail_img_url, song_urls = \
        extract_yt_info(playlist_url)
    path = get_desktop_folder()
    output_path = f'{path}/{album_title}'
    os.mkdir(output_path)

    max_workers = 4

    with tqdm(total=len(song_urls), desc="Processing Videos", unit="video") \
            as pbar:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) \
                as executor:
            future_to_url = {
                executor.submit(process_video, song_url, 
                                thumbnail_img_url, artist_name, 
                                album_title, output_path, pbar): song_url
                for song_url
                in song_urls
            }

            for future in concurrent.futures.as_completed(future_to_url):
                song_url = future_to_url[future]
                try:
                    future.result()
                except Exception as e:
                    print(f"Error processing {song_url}: {e}")


def get_desktop_folder():
    home_dir = os.path.expanduser("~")
    if os.name == 'posix':  # Unix/Linux/Mac
        desktop_folder = os.path.join(home_dir, 'Desktop')
    return desktop_folder


def process_video(song_url, thumbnail_img_url, artist_name,
                  album_title, output_path, pbar):
    try:
        video_title = download_video(video_url=song_url,
                                     output_path=output_path)
        mp3_file_path = convert_video_format(
                            video_title=video_title,
                            video_filename=f'{video_title}.mp4',
                            output_path=output_path)
        attach_metadata(mp3_file_path,
                        thumbnail_img_url, artist_name, album_title,
                        video_title, output_path)
        pbar.update(1)
    except Exception as e:
        print(f"Error processing {song_url}: {e}")


def sanitize_filename(filename):
    return filename.replace(' ', '_')


def sanitize_title(title):
    keywords_to_exclude = ['official video', 'official music video', 'lyrics', 
                           'audio', 'hd', 'hq', 'remix']
    title_lower = title.lower()
    for keyword in keywords_to_exclude:
        title_lower = title_lower.replace(keyword, '')
    return title_lower.strip()


def extract_yt_info(playlist_url):
    try:
        response = requests.get(playlist_url)
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
                    artist_name = (
                        data['header']['playlistHeaderRenderer']
                        ['subtitle']['simpleText'].split(' • ')[0])
                    album_name = (
                        data['metadata']['playlistMetadataRenderer']
                        ['albumName'])
                    thumbnail_img_url = (
                        data['sidebar']['playlistSidebarRenderer']
                        ['items'][0]['playlistSidebarPrimaryInfoRenderer']
                        ['thumbnailRenderer']
                        ['playlistCustomThumbnailRenderer']
                        ['thumbnail']['thumbnails'][-1]['url']
                    )
                    song_urls = [(
                        d['playlistVideoRenderer']['navigationEndpoint']
                        ['commandMetadata']['webCommandMetadata']['url']
                    ) for d in (
                        data['contents']['twoColumnBrowseResultsRenderer']
                        ['tabs'][0]['tabRenderer']['content']
                        ['sectionListRenderer']['contents'][0]
                        ['itemSectionRenderer']['contents'][0]
                        ['playlistVideoListRenderer']['contents'])]
                    return artist_name, album_name, thumbnail_img_url, [
                        f'www.youtube.com{url}' for url in song_urls]
        raise Exception("Not found")
    except Exception as e:
        print(f"extract_yt_info: {e}")
        return None


def attach_metadata(
        mp3_file_path, thumbnail_img_url, artist_name, album_title, title, 
        output_path):
    audiofile = eyed3.load(f'{output_path}/{mp3_file_path}')
    response = urllib.request.urlopen(thumbnail_img_url)
    imagedata = response.read()

    audiofile.tag.artist = artist_name
    audiofile.tag.album_artist = artist_name
    audiofile.tag.title = title
    audiofile.tag.album = album_title
    audiofile.tag.images.set(3, imagedata, "image/jpeg", u"cover")
    audiofile.tag.save()


def download_video(video_url, output_path='.'):
    yt = YouTube(video_url)
    video_stream = yt.streams.get_highest_resolution()
    video_title = yt.title
    video_stream.download(output_path)
    return video_title


def convert_video_format(video_title, video_filename, output_path,
                         input_format='mp4', output_format='mp3'):
    sanitized_filename = sanitize_filename(video_filename)
    os.rename(f'{output_path}/{video_filename}',
              f'{output_path}/{sanitized_filename}')
    audio = AudioSegment.from_file(f'{output_path}/{sanitized_filename}',
                                   format=input_format)
    audio_file_path = f'{video_title}.{output_format}'
    audio.export(f'{output_path}/{audio_file_path}', codec=output_format)
    os.remove(f'{output_path}/{sanitized_filename}')
    return audio_file_path


if __name__ == '__main__':
    main()
