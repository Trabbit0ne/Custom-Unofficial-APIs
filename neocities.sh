#!/bin/bash

# Check if a tag is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

# Assign the tag to a variable
tag="$1"

# Inform the user about the operation
echo -e "\e[32mExtracting URLs for the tag: $tag...\e[0m"

# Fetch URLs, filter and exclude unwanted URLs
urls=$(curl -s "https://neocities.org/browse?tag=$tag" | \
grep -oP 'href="https?://[^"]+' | \
grep -oP 'https?://\S+' | \
grep -v -e 'https://duckduckgo.com/' \
         -e 'https://neocities.org' \
         -e 'https://github.com/neocities' \
         -e 'https://bsky.app/profile/neocities.org' | \
sort | uniq)

# Check if any URLs were found
if [ -z "$urls" ]; then
  echo -e "\e[31mNo URLs found for the tag: $tag.\e[0m"
  exit 1
fi

# Display the URLs
echo "$urls"

# Inform the user when the extraction is complete
echo -e "\e[32mURL extraction complete.\e[0m"
