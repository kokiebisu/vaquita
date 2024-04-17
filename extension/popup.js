document.getElementById("sendRequestBtn").addEventListener("click", () => {
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    const currentUrl = tabs[0].url;
    chrome.runtime.sendMessage(
      {
        command: "sendRequest",
        url: currentUrl,
      },
      function (response) {
        console.log(response.status);
      }
    );
  });
});
