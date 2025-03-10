const countElement = document.getElementById("visitor-count");

fetch("https://hgrg6yb2r5.execute-api.us-east-1.amazonaws.com/VisitorCounter")
  .then(response => {
    if (!response.ok) {
      throw new Error("Network response was not ok");
    }
    return response.json();
  })
  .then(data => {
    console.log("API Response:", data);
    countElement.textContent = data;  // Make sure this key matches your API response
  })
  .catch(error => {
    console.error("Error fetching visitor count:", error);
    countElement.textContent = "Error";
  });