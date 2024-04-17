chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.command === "sendRequest") {
    fetch("http://localhost:4567/process", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ url: message.url }),
    })
      .then((response) => response.json())
      .then((data) => {
        console.log("Received response:", data);
        sendResponse({ status: "Received", data: data });
      })
      .catch((error) => {
        console.error("Fetch error:", error);
        sendResponse({ status: "Error", message: error.toString() });
      });
    return true;
  }
});
