async function fetchVisitorCount() {
    try {
        const response = await fetch("https://hgrg6yb2r5.execute-api.us-east-1.amazonaws.com/VisitorCounter");
        const data = await response.json();
        document.getElementById("visitor-count").innerText = data.visitorCount;
    } catch (error) {
        console.error("Error fetching visitor count:", error);
        document.getElementById("visitor-count").innerText = "Error loading visitor count";
    }
}
fetchVisitorCount();