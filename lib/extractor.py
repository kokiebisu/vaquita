import abc
import re
import requests
import json

from bs4 import BeautifulSoup


class InfoExtractor(abc.ABC):
    @abc.abstractmethod
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
                        album_name = (
                            data['metadata']['playlistMetadataRenderer']
                            ['albumName'])
                        song_urls = []
                        for d in (
                            data['contents']['twoColumnBrowseResultsRenderer']['tabs'][0][
                                'tabRenderer']['content']['sectionListRenderer']['contents'][0][
                                    'itemSectionRenderer']['contents'][0]['playlistVideoListRenderer'][
                                        'contents']
                                ):
                            if 'playlistVideoRenderer' in d:
                                song_urls.append(d['playlistVideoRenderer']['navigationEndpoint'][
                                    'commandMetadata']['webCommandMetadata']['url'])
                        return album_name, [
                            f'https://www.youtube.com{url}' for url in song_urls]
            raise Exception("Not found")
        except Exception as e:
            print(f"Error extracting youtube playlist info: {e}")
            return None


class SongInfoExtractor(InfoExtractor):
    @classmethod
    def extract(cls, video_url):
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
                        for panel in data.get('engagementPanels', []):
                            if 'engagementPanelSectionListRenderer' in panel:
                                panel_data = panel['engagementPanelSectionListRenderer']
                                content_list = panel_data['content']
                                if 'structuredDescriptionContentRenderer' in content_list:
                                    item_data = content_list[
                                        'structuredDescriptionContentRenderer']
                                    cards = item_data.get('items', [])
                                    for card in cards:
                                        if 'horizontalCardListRenderer' in card:
                                            return cls._extract_song(card)
                                        if 'videoDescriptionHeaderRenderer' in card:
                                            return cls._extract_video(card, video_url)
                                        raise Exception('Data cannot be extracted')
            raise Exception("Not found")
        except Exception as e:
            print(f"Error extracting youtube song info: {e}")
            return None

    def _extract_song(card):
        card_data = card['horizontalCardListRenderer']
        cards_in_list = card_data.get('cards', [])
        for card_item in cards_in_list:
            if 'videoAttributeViewModel' in card_item:
                data = card_item['videoAttributeViewModel']
                song_title = data['title']
                artist_name = data['subtitle']
                album_name = data['secondarySubtitle']['content']
                cover_img_url = data['image']['sources'][0]['url']
                return song_title, artist_name, album_name, cover_img_url

    def _extract_video(card, video_url):
        card_data = card['videoDescriptionHeaderRenderer']
        song_title = card_data['title']['runs'][0]['text']
        artist_name = card_data['channel']['simpleText']
        album_name = song_title
        return song_title, artist_name, album_name, video_url
