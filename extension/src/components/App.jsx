import React, { useState, useEffect, useReducer, useMemo } from "react";
import CommandButton from "./CommandButton";
import Spinner from "./Spinner";

const initialState = {
  isUrlAudioLoading: false,
  isUrlVideoLoading: false,
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
  const [domain, setDomain] = useState(null);
  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      setCurrentUrl(tabs[0].url);
    });
  }, []);

  useEffect(() => {
    if (currentUrl) {
      const newDomain = new URL(currentUrl).hostname;
      setDomain(newDomain);
    }
  }, [currentUrl]);

  const handleCommand = (command, loadingType, outputType) => {
    const message = {
      command,
      outputType,
      ...(command === "url" && { url: currentUrl, domain: domain }),
    };
    dispatch({ type: "START_LOAD", payload: loadingType });
    chrome.runtime.sendMessage(message, (response) => {
      dispatch({ type: "STOP_LOAD", payload: loadingType });
    });
  };

  const isValidPlatform = useMemo(() => {
    return domain && ["music.youtube.com", "www.youtube.com"].includes(domain);
  }, [domain]);

  return (
    <div className="w-64 h-64 p-4 space-y-3">
      <div className="text-xl font-bold">Youtube Downloader</div>
      {domain &&
        (state.isUrlAudioLoading ? (
          <Spinner />
        ) : (
          <>
            <button
              type="button"
              disabled={
                state.isUrlAudioLoading ||
                state.isRecommendationsLoading ||
                state.isTrendingLoading ||
                !isValidPlatform
              }
              className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
              onClick={() => handleCommand("url", "isUrlAudioLoading", "audio")}
            >
              {isValidPlatform
                ? "Process URL (Audio)"
                : "You must be on the right platform"}
            </button>
          </>
        ))}
      {domain &&
        domain == "www.youtube.com" &&
        (state.isUrlVideoLoading ? (
          <Spinner />
        ) : (
          <button
            type="button"
            disabled={
              state.isUrlAudioLoading ||
              state.isRecommendationsLoading ||
              state.isTrendingLoading ||
              !isValidPlatform
            }
            className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
            onClick={() => handleCommand("url", "isUrlVideoLoading", "video")}
          >
            {isValidPlatform
              ? "Process URL (Video)"
              : "You must be on the right platform"}
          </button>
        ))}
      <CommandButton
        label="Process Recommendations"
        loadingState={state.isRecommendationsLoading}
        disabledStates={[state.isUrlAudioLoading, state.isTrendingLoading]}
        onClick={() =>
          handleCommand("recommendations", "isRecommendationsLoading", "audio")
        }
      />
      <CommandButton
        label="Process Trending"
        loadingState={state.isTrendingLoading}
        disabledStates={[
          state.isUrlAudioLoading,
          state.isRecommendationsLoading,
        ]}
        onClick={() => handleCommand("trending", "isTrendingLoading", "audio")}
      />
    </div>
  );
};

export default App;
