from pathlib import Path
import abc

from pytube import YouTube
from pydub import AudioSegment
import eyed3
import urllib

from . import utils

eyed3.log.setLevel("ERROR")


class Processor(abc.ABC):
    @abc.abstractclassmethod
    def process():
        pass

    @staticmethod
    def _attach_metadata(video_title, thumbnail_img_url, artist_name,
                         album_title, title, output_path):
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

    @staticmethod
    def _download_video(video_url, artist_name, output_path='.'):
        try:
            yt = YouTube(video_url)
            video_stream = yt.streams.get_highest_resolution()
            video_title = utils.sanitize_filename(
                yt.title, extra_keywords=artist_name.lower().split(' '))
            video_stream.download(output_path, filename=f'{video_title}.mp4')
        except Exception as e:
            print(f'Error downloading video: {e}')
            raise e
        return video_title

    @staticmethod
    def _convert_video_to_audio(video_title, output_path,
                                input_format='mp4', output_format='mp3'):
        try:
            source_path = Path(output_path) / f'{video_title}.{input_format}'
            dest_path = Path(output_path) / f'{video_title}.{output_format}'
            audio = AudioSegment.from_file(source_path, format=input_format)
            audio.export(dest_path, codec=output_format)
        except Exception as e:
            print(f'Error converting video format: {e}')
            raise e


class VideoProcessor(Processor):
    @classmethod
    def process(cls, song_url, thumbnail_img_url, artist_name,
                album_title, output_path):
        try:
            video_title = cls._download_video(video_url=song_url,
                                              artist_name=artist_name.lower(),
                                              output_path=output_path)
            cls._convert_video_to_audio(
                video_title=video_title, output_path=output_path)
            cls._attach_metadata(video_title, thumbnail_img_url, artist_name, 
                                 album_title, video_title, output_path)
        except Exception as e:
            print(f"Error processing {song_url}: {e}")
            raise e


class AudioProcessor(Processor):
    @classmethod
    def process(cls, song_url, song_title, artist_name, album_name,
                thumbnail_img_url, output_path):
        try:
            cls._download_video(video_url=song_url,
                                artist_name=artist_name.lower(),
                                output_path=output_path)
            cls._convert_video_to_audio(song_title, output_path)
            cls._attach_metadata(song_title, thumbnail_img_url, artist_name,
                                 album_name, song_title, output_path)
        except Exception as e:
            print(f"Error processing {song_url}: {e}")
            raise e
