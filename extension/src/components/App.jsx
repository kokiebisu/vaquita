import React from "react";
import { useState, useEffect } from "react";

const urlTypes = {
  YOUTUBE_PLAYLIST: "YOUTUBE_PLAYLIST",
  YOUTUBE_SONG: "YOUTUBE_SONG",
  YOUTUBE_MUSIC_PLAYLIST: "YOUTUBE_MUSIC_PLAYLIST",
  YOUTUBE_MUSIC_SONG: "YOUTUBE_MUSIC_SONG",
};

const App = () => {
  const [currentUrl, setCurrentUrl] = useState(null);
  const [urlType, setUrlType] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isRecommendationsLoading, setIsRecommendationsLoading] =
    useState(false);
  const [isTrendingLoading, setIsTrendingLoading] = useState(false);

  useEffect(() => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      setCurrentUrl(tabs[0].url);
    });
  }, []);

  useEffect(() => {
    if (currentUrl) {
      setUrlType(classifyUrl(currentUrl));
    }
  }, [currentUrl]);

  const onProcessUrl = () => {
    setIsLoading(true);
    chrome.runtime.sendMessage(
      {
        command: "url",
        url: currentUrl,
      },
      function (response) {
        console.log(response);
        setIsLoading(false);
      }
    );
  };

  const onProcessRecommendations = () => {
    setIsLoading(true);
    chrome.runtime.sendMessage(
      {
        command: "recommendations",
      },
      function (response) {
        console.log(response);
        setIsLoading(false);
      }
    );
  };

  const onProcessTrending = () => {
    setIsLoading(true);
    chrome.runtime.sendMessage(
      {
        command: "trending",
      },
      function (response) {
        console.log(response);
        setIsLoading(false);
      }
    );
  };

  const onProcessMusicPlaylist = () => {
    setIsLoading(true);
    chrome.runtime.sendMessage(
      {
        command: "playlist",
        url: currentUrl,
      },
      function (response) {
        console.log(response);
        setIsLoading(false);
      }
    );
  };

  const classifyUrl = (url) => {
    if (url.includes("music.youtube.com/watch")) {
      return urlTypes.YOUTUBE_MUSIC_SONG;
    } else if (url.includes("music.youtube.com/playlist")) {
      return urlTypes.YOUTUBE_MUSIC_PLAYLIST;
    } else if (url.includes("youtube.com/playlist")) {
      return urlTypes.YOUTUBE_PLAYLIST;
    } else if (url.includes("youtube.com/watch")) {
      return urlTypes.YOUTUBE_SONG;
    }
    return "Unknown Type";
  };

  const getDisplayMessage = (urlType) => {
    console.log("URL TYPE: ", urlType);
    switch (urlType) {
      case urlTypes.YOUTUBE_MUSIC_PLAYLIST:
        return "Process this playlist";
      case urlTypes.YOUTUBE_MUSIC_SONG:
        return "Process this song";
      case urlTypes.YOUTUBE_PLAYLIST:
        return "Process this playlist";
      case urlTypes.YOUTUBE_SONG:
        return "Process this song";
      default:
        return "Make sure you are on a youtube playlist/song url!";
    }
  };

  const getProcessMethod = (urlType) => {
    switch (urlType) {
      case urlTypes.YOUTUBE_MUSIC_PLAYLIST:
        return onProcessMusicPlaylist();
      case urlTypes.YOUTUBE_MUSIC_SONG:
        return onProcessMusicSong();
      case urlTypes.YOUTUBE_PLAYLIST:
        return onProcessUrl();
      case urlTypes.YOUTUBE_SONG:
        return onProcessUrl();
    }
  };

  return (
    <div className="w-64 h-64 p-4 space-y-3">
      <div className="text-xl font-bold">Youtube Downloader</div>
      {getDisplayMessage(urlType) !== null ? (
        isLoading ? (
          <div>Loading....</div>
        ) : (
          <button
            type="button"
            className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
            onClick={() => getProcessMethod(urlType)}
          >
            {getDisplayMessage(urlType)}
          </button>
        )
      ) : (
        <div>Make sure you are on a youtube url</div>
      )}
      {isRecommendationsLoading ? (
        <div>Loading...</div>
      ) : (
        <button
          type="button"
          className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
          onClick={onProcessRecommendations}
        >
          Recommendations
        </button>
      )}
      {isTrendingLoading ? (
        <div>Loading...</div>
      ) : (
        <button
          type="button"
          className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
          onClick={onProcessTrending}
        >
          Trending
        </button>
      )}
    </div>
  );
};

export default App;
