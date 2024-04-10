import os
from pathlib import Path
import concurrent.futures
import sys

from tqdm import tqdm

from lib.extractor import PlaylistInfoExtractor, SongInfoExtractor
from lib.processor import VideoProcessor
from lib.utils import get_desktop_folder


def _process_song(url, base_path):
    try:
        song_title, artist_name, album_name, thumbnail_img_url = SongInfoExtractor.extract(url)
        VideoProcessor.process(url, song_title, artist_name, album_name, thumbnail_img_url, base_path)
        return True
    except Exception as e:
        print(f"Error processing {url}: {e}")
        return False


def _process_playlist(urls, base_path):
    max_workers = 4
    with tqdm(total=len(urls), desc="Processing Videos", unit="video") as pbar:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(_process_song, url, base_path) for url in urls]
            for future in concurrent.futures.as_completed(futures):
                if future.result():
                    pbar.update(1)


def main():
    url = sys.argv[1]
    path = get_desktop_folder()
    if 'playlist' in url:
        album_name, video_urls = \
            PlaylistInfoExtractor.extract(url)
        output_path = Path(f'{path}/{album_name}')
        os.mkdir(output_path)
        _process_playlist(video_urls, base_path=output_path)
    else:
        song_title, artist_name, album_name, \
                        thumbnail_img_url = SongInfoExtractor.extract(url)
        song_title = song_title.replace('/', '-')
        VideoProcessor.process(url, song_title, artist_name, album_name,
                               thumbnail_img_url, output_path=Path(path))
        output_path = Path(f'{path}/{song_title}.mp3')
    with open("output_dir.txt", "w") as file:
        file.write(str(output_path))


if __name__ == '__main__':
    main()
