const countElement = document.getElementById("visitor-count");

fetch("YOUR_API_GATEWAY_URL_HERE")
  .then(response => response.json())
  .then(data => {
    countElement.textContent = data.visitorCount;  // Make sure the key matches what your API returns
  })
  .catch(error => {
    console.error("Error fetching visitor count:", error);
    countElement.textContent = "Error";
  });