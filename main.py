import concurrent.futures
import os
import sys

from tqdm import tqdm

from lib import extractor, utils, video


def get_youtube_playlist_url():
    if len(sys.argv) < 2:
        return input("Provide the YouTube album playlist URL: ")
    else:
        return sys.argv[1]


def main():
    playlist_url = get_youtube_playlist_url()

    artist_name, album_title, thumbnail_img_url, song_urls = \
        extractor.extract_yt_info(playlist_url)
    path = utils.get_desktop_folder()
    output_path = f'{path}/{album_title}'
    os.mkdir(output_path)

    max_workers = 4

    with tqdm(total=len(song_urls), desc="Processing Videos", unit="video") \
            as pbar:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) \
                as executor:
            future_to_url = {
                executor.submit(video.process_video, song_url,
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
