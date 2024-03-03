import abc
import re
import requests
import json

from bs4 import BeautifulSoup


class InfoExtractor(abc.ABC):
    @abc.abstractstaticmethod
    def extract(video_url):
        pass


class PlaylistInfoExtractor(InfoExtractor):
    @staticmethod
    def extract(video_url):
        try:
            response = requests.get(video_url)
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
                            data['contents']['twoColumnBrowseResultsRenderer']
                            ['tabs'][0]['tabRenderer']['content']
                            ['sectionListRenderer']['contents'][0]
                            ['itemSectionRenderer']['contents'][0]
                            ['playlistVideoListRenderer']['contents'][0]
                            ['playlistVideoRenderer']['shortBylineText']
                            ['runs'][0]['text']
                        )
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


class SongInfoExtractor(abc.ABC):
    @staticmethod
    def extract(video_url):
        try:
            response = requests.get(video_url)
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
                        data = (
                            data['engagementPanels'][2]
                            ['engagementPanelSectionListRenderer']['content']
                            ['structuredDescriptionContentRenderer']
                            ['items'][2]['horizontalCardListRenderer']['cards'][0]
                            ['videoAttributeViewModel']
                        )
                        song_title = data['title']
                        artist_name = data['subtitle']
                        album_name = data['secondarySubtitle']['content']
                        thumbnail_img_url = data['image']['sources'][0]['url']
                        return song_title, artist_name, album_name, \
                            thumbnail_img_url
            raise Exception("Not found")
        except Exception as e:
            print(f"Error extracting youtube info: {e}")
            return None
