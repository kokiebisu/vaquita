import os
from pathlib import Path
import abc
import cv2

from pytube import YouTube
from pydub import AudioSegment
import eyed3
import requests


from . import utils

eyed3.log.setLevel("ERROR")


class Processor(abc.ABC):
    @abc.abstractclassmethod
    def process():
        pass

    @staticmethod
    def _attach_metadata(video_title, cover_img_path, artist_name,
                         album_title, title, output_path):
        try:
            audiofile = eyed3.load(Path(output_path) / f'{video_title}.mp3')

            # If file extension is '.gif' then read the gif and attach it to the audiofile.tag.images
            if str(cover_img_path).endswith('.gif'):
                with open(cover_img_path, 'rb') as f:
                    gifdata = f.read()
                audiofile.tag.images.set(3, gifdata, "image/gif", u"cover")

            # If file extension if '.jpg' then read the image and attach it to audiofile.tag.images
            elif str(cover_img_path).endswith('.jpg'):
                with open(cover_img_path, 'rb') as f:
                    imagedata = f.read()
                audiofile.tag.images.set(3, imagedata, "image/jpeg", u"cover")

            audiofile.tag.artist = artist_name
            audiofile.tag.album_artist = artist_name
            audiofile.tag.title = title
            audiofile.tag.album = album_title
            audiofile.tag.save()
        except Exception as e:
            print(f'Error attaching metadata: {e}')
            raise e

    @staticmethod
    def _download_video(video_url, video_title, artist_name='', output_path='.'):
        try:
            yt = YouTube(video_url)
            video_stream = yt.streams.get_highest_resolution()
            if artist_name:
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
    '''
    A class used for when processing a single song
    '''
    @classmethod
    def process(cls, url, video_title, artist_name, album_name,
                thumbnail_img_url, output_path):
        try:
            cls._download_video(video_url=url,
                                video_title=video_title,
                                output_path=output_path)
            cls._convert_video_to_audio(video_title, output_path)
            desktop_path = utils.get_desktop_folder()
            if thumbnail_img_url != url:
                download_image(thumbnail_img_url, Path(desktop_path / 'cover.jpg'))
            else:
                capture_image(Path(desktop_path / f'{video_title}.mp4'), Path(desktop_path / 'cover.jpg'))
            cls._attach_metadata(video_title, Path(desktop_path / 'cover.jpg'), artist_name,
                                 album_name, video_title, output_path)
            os.remove(Path(output_path) / f'{video_title}.mp4')
        except Exception as e:
            print(f"Error processing {url}: {e}")
            raise e


def download_image(image_url, output_path):
    """
    Downloads an image from the given URL and saves it to the specified directory.

    Args:
        image_url (str): The URL of the image to download.
        save_directory (str): The directory where the image will be saved. Defaults to 'images'.

    Returns:
        str: The local path where the image is saved.
    """
    response = requests.get(image_url)
    if response.status_code == 200:
        with open(output_path, 'wb') as f:
            f.write(response.content)
        return output_path
    else:
        print(f"Failed to download image from URL: {image_url}")
        return None


def capture_image(video_path, output_path):
    try:
        # Open the video file
        cap = cv2.VideoCapture(str(video_path))

        # Read the first frame from the video
        success, frame = cap.read()

        if success:
            # Resize the frame to a square thumbnail size
            min_dim = min(frame.shape[0], frame.shape[1])
            square_frame = frame[:min_dim, :min_dim]

            # Save the square frame as a JPEG image
            cv2.imwrite(str(output_path), square_frame)

        # Release the video capture object
        cap.release()
    except Exception as e:
        print(f'Error capturing image: {e}')
        raise e
