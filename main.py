from pathlib import Path
import concurrent.futures
import sys

from tqdm import tqdm

from lib.extractor import PlaylistInfoExtractor, SongInfoExtractor
from lib.processor import AudioProcessor, VideoProcessor
from lib.utils import get_desktop_folder


def process_playlist(artist_name, album_title, thumbnail_img_url, song_urls,
                     output_path):
    max_workers = 4
    with tqdm(total=len(song_urls), desc="Processing Videos", unit="video") \
            as pbar:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) \
                as executor:
            future_to_url = {
                executor.submit(VideoProcessor.process, song_url,
                                thumbnail_img_url, artist_name,
                                album_title, output_path): song_url
                for song_url
                in song_urls
            }

            for future in concurrent.futures.as_completed(future_to_url):
                song_url = future_to_url[future]
                try:
                    future.result()
                    pbar.update(1)
                except Exception as e:
                    print(f"Error processing {song_url}: {e}")


def main():
    url = sys.argv[1]
    path = get_desktop_folder()
    if 'playlist' in url:
        artist_name, album_title, thumbnail_img_url, song_urls = \
            PlaylistInfoExtractor.extract(url)
        output_path = Path(path) / album_title
        process_playlist(artist_name, album_title, thumbnail_img_url, 
                         song_urls, output_path)
    else:
        song_title, artist_name, album_name, \
                        thumbnail_img_url = SongInfoExtractor.extract(url)
        AudioProcessor.process(url, song_title, artist_name, album_name,
                               thumbnail_img_url, output_path=Path(path))
        output_path = Path(f'{path}/{song_title}.mp3')
    with open("output_dir.txt", "w") as file:
        file.write(str(output_path))


if __name__ == '__main__':
    main()
