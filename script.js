const counter = document.getElementById('visitor-count');

async function getVisitorCount() {
    try {
        const response = await fetch('https://hgrg6yb2r5.execute-api.us-east-1.amazonaws.com/VisitorCounter'); // Replace with your actual API Gateway URL
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        const data = await response.json();
        counter.innerText = data.visitorCount || '0'; // Default to 0 if undefined
    } catch (error) {
        console.error('Error fetching visitor count:', error);
        counter.innerText = 'Error loading visitor count';
    }
}

getVisitorCount();