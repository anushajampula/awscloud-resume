const countElement = document.getElementById("visitor-count");

fetch("YOUR_API_GATEWAY_URL_HERE")
  .then(response => {
    if (!response.ok) {
      throw new Error("Network response was not ok");
    }
    return response.json();
  })
  .then(data => {
    console.log("API Response:", data);
    countElement.textContent = data.visitorCount;  // Make sure this key matches your API response
  })
  .catch(error => {
    console.error("Error fetching visitor count:", error);
    countElement.textContent = "Error";
  });