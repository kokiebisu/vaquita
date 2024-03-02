import eyed3
from lib import video

eyed3.log.setLevel("ERROR")


def process_song(song_url, song_title, artist_name, album_name,
                 thumbnail_img_url, output_path):
    try:
        video.download_video(video_url=song_url,
                             artist_name=artist_name.lower(),
                             album_title=album_name.lower(),
                             output_path=output_path)
        video.convert_video_format(song_title, output_path)
        video.attach_metadata(song_title, thumbnail_img_url, artist_name,
                              album_name, song_title, output_path)
    except Exception as e:
        print(f"Error processing {song_url}: {e}")
        raise e
