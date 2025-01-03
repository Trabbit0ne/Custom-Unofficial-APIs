import requests
import re
import sys

# Check if the user provided a tag
if len(sys.argv) != 2:
    print("Usage: python extract_urls.py <tag>")
    sys.exit(1)

# Get the tag from command-line argument
tag = sys.argv[1]

# Define the URLs to exclude
exclude_urls = [
    "https://duckduckgo.com/",
    "https://neocities.org",
    "https://github.com/neocities",
    "https://bsky.app/profile/neocities.org",
    "http://status.neocitiesops.net/",
]

# Fetch the webpage content
url = f"https://neocities.org/browse?tag={tag}"
response = requests.get(url)

# If the request was successful
if response.status_code == 200:
    # Use regex to find all URLs in href attributes
    urls = re.findall(r'href="(https?://\S+)"', response.text)

    # Filter out the unwanted URLs
    filtered_urls = [url for url in urls if url not in exclude_urls]

    # Display the filtered URLs
    print(f"Extracted URLs for tag '{tag}':")
    for url in filtered_urls:
        print(url)
else:
    print(f"Failed to retrieve the page for tag '{tag}'. HTTP Status code: {response.status_code}")
