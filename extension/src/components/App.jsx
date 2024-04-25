import React, { useState, useEffect, useReducer } from "react";

import CommandButton from "./CommandButton";
import Spinner from "./Spinner";

const urlTypes = {
  YOUTUBE_PLAYLIST: "YOUTUBE_PLAYLIST",
  YOUTUBE_SONG: "YOUTUBE_SONG",
  YOUTUBE_MUSIC_PLAYLIST: "YOUTUBE_MUSIC_PLAYLIST",
  YOUTUBE_MUSIC_SONG: "YOUTUBE_MUSIC_SONG",
};

const initialState = {
  isLoading: false,
  isRecommendationsLoading: false,
  isTrendingLoading: false,
};

function reducer(state, action) {
  switch (action.type) {
    case "START_LOAD":
      return { ...state, [action.payload]: true };
    case "STOP_LOAD":
      return { ...state, [action.payload]: false };
    default:
      return state;
  }
}

const App = () => {
  const [currentUrl, setCurrentUrl] = useState(null);
  const [urlType, setUrlType] = useState(null);
  const [state, dispatch] = useReducer(reducer, initialState);

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

  const handleCommand = (command, key) => {
    dispatch({ type: "START_LOAD", payload: key });
    chrome.runtime.sendMessage({ command, url: currentUrl }, (response) => {
      dispatch({ type: "STOP_LOAD", payload: key });
    });
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

  const getDisplayMessage = () => {
    switch (urlType) {
      case urlTypes.YOUTUBE_MUSIC_PLAYLIST:
      case urlTypes.YOUTUBE_PLAYLIST:
        return "Process this playlist";
      case urlTypes.YOUTUBE_MUSIC_SONG:
      case urlTypes.YOUTUBE_SONG:
        return "Process this song";
      default:
        return "Make sure you are on a youtube playlist/song url!";
    }
  };

  const getProcessMethod = () => {
    switch (urlType) {
      case urlTypes.YOUTUBE_MUSIC_PLAYLIST:
      case urlTypes.YOUTUBE_PLAYLIST:
        return () => handleCommand("playlist", "isLoading");
      case urlTypes.YOUTUBE_MUSIC_SONG:
      case urlTypes.YOUTUBE_SONG:
        return () => handleCommand("song", "isLoading");
      default:
        return null;
    }
  };

  return (
    <div className="w-64 h-64 p-4 space-y-3">
      <div className="text-xl font-bold">Youtube Downloader</div>
      {urlType &&
        (state.isLoading ? (
          <Spinner />
        ) : (
          <button
            type="button"
            disabled={state.isRecommendationsLoading || state.isTrendingLoading}
            className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
            onClick={getProcessMethod()}
          >
            {getDisplayMessage()}
          </button>
        ))}
      <CommandButton
        label="Recommendations"
        loadingState={state.isRecommendationsLoading}
        disabledStates={[state.isLoading, state.isTrendingLoading]}
        onClick={() =>
          handleCommand("recommendations", "isRecommendationsLoading")
        }
      />
      <CommandButton
        label="Trending"
        loadingState={state.isTrendingLoading}
        disabledStates={[state.isLoading, state.isRecommendationsLoading]}
        onClick={() => handleCommand("trending", "isTrendingLoading")}
      />
    </div>
  );
};

export default App;
