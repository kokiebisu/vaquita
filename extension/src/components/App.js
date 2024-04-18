import React from "react";

const App = () => {
  const onProcessUrl = () => console.log("process url");
  const onProcessRecommendations = () => console.log("process recommendations");
  const onProcessTrending = () => console.log("process trending");
  const onProcessMusicPlaylist = () => console.log("process music");
  return (
    <div>
      <button onClick={onProcessUrl}>Process Youtube URL</button>
      <button onClick={onProcessRecommendations}>
        Process Recommendations
      </button>
      <button onClick={onProcessTrending}>Process Trending</button>
      <button onClick={onProcessMusicPlaylist}>Process Playlist</button>
    </div>
  );
};

export default App;
