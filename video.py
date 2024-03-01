from pathlib import Path
from utils import Utils
import os

from pytube import YouTube
from pydub import AudioSegment
import urllib
import eyed3


eyed3.log.setLevel("ERROR")


class Video:
    @classmethod
    def process_video(cls, song_url, thumbnail_img_url, artist_name,
                      album_title, output_path, pbar):
        try:
            video_title = cls.download_video(video_url=song_url,
                                             artist_name=artist_name.lower(),
                                             album_title=album_title.lower(),
                                             output_path=output_path)
            cls.convert_video_format(
                                video_title=video_title,
                                output_path=output_path)
            cls.attach_metadata(video_title,
                                thumbnail_img_url, artist_name, album_title,
                                video_title, output_path)
            pbar.update(1)
        except Exception as e:
            print(f"Error processing {song_url}: {e}")
            raise e

    @staticmethod
    def download_video(video_url, artist_name, album_title, output_path='.'):
        try:
            yt = YouTube(video_url)
            video_stream = yt.streams.get_highest_resolution()
            
            video_title = Utils.sanitize_filename(
                yt.title, extra_keywords=artist_name.split(' ')
                + album_title.split(' '))
            video_stream.download(output_path, filename=f'{video_title}.mp4')
        except Exception as e:
            print(f'Error downloading video: {e}')
            raise e
        return video_title

    @staticmethod
    def convert_video_format(video_title, output_path,
                             input_format='mp4', output_format='mp3'):
        try:
            video_title = Utils.sanitize_filename_without_stuff(video_title)
            source_path = Path(output_path) / f'{video_title}.{input_format}'
            dest_path = Path(output_path) / f'{video_title}.{output_format}'
            audio = AudioSegment.from_file(source_path, format=input_format)
            audio.export(dest_path, codec=output_format)
            os.remove(source_path)
        except Exception as e:
            print(f'Error converting video format: {e}')
            raise e

    @staticmethod
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