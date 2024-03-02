import re
import requests
import json

from bs4 import BeautifulSoup


def extract_yt_info(playlist_url):
    try:
        response = requests.get(playlist_url)
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
                        data['header']['playlistHeaderRenderer']
                        ['subtitle']['simpleText'].split(' • ')[0])
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
