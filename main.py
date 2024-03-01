import concurrent.futures
import os

from tqdm import tqdm
from extractor import Extractor

from utils import Utils
from video import Video


def main():
    playlist_url = input("Provide the Youtube album playlist URL\n")

    artist_name, album_title, thumbnail_img_url, song_urls = \
        Extractor.extract_yt_info(playlist_url)
    path = Utils.get_desktop_folder()
    output_path = f'{path}/{album_title}'
    os.mkdir(output_path)

    max_workers = 4

    with tqdm(total=len(song_urls), desc="Processing Videos", unit="video") \
            as pbar:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) \
                as executor:
            future_to_url = {
                executor.submit(Video.process_video, song_url,
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


if __name__ == '__main__':
    main()
