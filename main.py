from pathlib import Path
import concurrent.futures
import json
import os
import re
import urllib

from bs4 import BeautifulSoup
from pytube import YouTube
from pydub import AudioSegment
import requests
from tqdm import tqdm
import eyed3

eyed3.log.setLevel("ERROR")


def main():
    # playlist_url = input("Provide the Youtube album playlist URL\n")
    # album = input("What is the name of the album?\n")
    playlist_url = 'https://www.youtube.com/playlist?list=OLAK5uy_nQ-_YIDTrNSdH5xOf77UrR-KsO416sxxs'

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

    # write the output file path
    with open("output_dir.txt", "w") as file:
        file.write(output_path)


def get_desktop_folder():
    home_dir = Path.home()
    desktop_folder = home_dir / 'Desktop'
    return desktop_folder


def process_video(song_url, thumbnail_img_url, artist_name,
                  album_title, output_path, pbar):
    try:
        video_title = download_video(video_url=song_url,
                                     artist_name=artist_name.lower(),
                                     album_title=album_title.lower(),
                                     output_path=output_path)
        convert_video_format(
                            video_title=video_title,
                            output_path=output_path)
        attach_metadata(video_title,
                        thumbnail_img_url, artist_name, album_title,
                        video_title, output_path)
        pbar.update(1)
    except Exception as e:
        print(f"Error processing {song_url}: {e}")
        raise e


def sanitize_filename(filename, artist_name, album_title):
    try:
        keywords_to_exclude = ['official', 'video', 'music', 'video', 
                               'lyrics', 'audio', 'hd', 'hq', 'remix'] + \
                                   artist_name.split(' ') + \
                                   album_title.split(' ')
        words = filename.split()
        sanitized_words = []
        for word in words:
            if word == '-' or word == '/' or word == '|':
                break
            # Preserve original case for words containing apostrophes
            if "'" in word:
                sanitized_words.append(word)
            else:
                # Remove content after slash (/) or pipe (|) if present
                if '/' in word:
                    word = word.split('/')[0]
                elif '|' in word:
                    word = word.split('|')[0]
                elif '-' in word:
                    word = word.split('-')[0]

                sanitized_words.append(word.title() if word.lower() not in
                                       keywords_to_exclude else word)
        return ' '.join(sanitized_words)
    except Exception as e:
        print(f'Error sanitizing filename: {e}')
        raise e


def sanitize_filename_without_stuff(filename):
    try:
        keywords_to_exclude = ['official', 'video', 'music', 'video', 
                               'lyrics', 'audio', 'hd', 'hq', 'remix']
        words = filename.split()
        sanitized_words = []
        for word in words:
            if word == '-' or word == '/' or word == '|':
                break
            # Preserve original case for words containing apostrophes
            if "'" in word:
                sanitized_words.append(word)
            else:
                # Remove content after slash (/) or pipe (|) if present
                if '/' in word:
                    word = word.split('/')[0]
                elif '|' in word:
                    word = word.split('|')[0]
                elif '-' in word:
                    word = word.split('-')[0]

                sanitized_words.append(word.title() if word.lower() not in
                                       keywords_to_exclude else word)
        return ' '.join(sanitized_words)
    except Exception as e:
        print(f'Error sanitizing filename: {e}')
        raise e


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
        print(f"Error extracting youtube info: {e}")
        return None


def attach_metadata(
        video_title, thumbnail_img_url, artist_name, album_title, title, 
        output_path):
    try:
        audiofile = eyed3.load(Path(output_path) / f'{video_title}.mp3')
        response = urllib.request.urlopen(thumbnail_img_url)
        imagedata = response.read()

        audiofile.tag.artist = artist_name
        audiofile.tag.album_artist = artist_name
        audiofile.tag.title = title
        audiofile.tag.album = album_title
        audiofile.tag.images.set(3, imagedata, "image/jpeg", u"cover")
        audiofile.tag.save()
    except Exception as e:
        print(f'Error attaching metadata: {e}')
        raise e


def download_video(video_url, artist_name, album_title, output_path='.'):
    try:
        yt = YouTube(video_url)
        video_stream = yt.streams.get_highest_resolution()
        video_title = sanitize_filename(yt.title, artist_name, album_title)
        video_stream.download(output_path, filename=f'{video_title}.mp4')
    except Exception as e:
        print(f'Error downloading video: {e}')
        raise e
    return video_title


def convert_video_format(video_title, output_path,
                         input_format='mp4', output_format='mp3'):
    try:
        video_title = sanitize_filename_without_stuff(video_title)
        source_path = Path(output_path) / f'{video_title}.{input_format}'
        dest_path = Path(output_path) / f'{video_title}.{output_format}'
        audio = AudioSegment.from_file(source_path, format=input_format)
        audio.export(dest_path, codec=output_format)
        os.remove(source_path)
    except Exception as e:
        print(f'Error converting video format: {e}')
        raise e


if __name__ == '__main__':
    main()
