#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Function to fetch user ID from username
get_user_id() {
    local username="$1"
    local url="https://users.roblox.com/v1/usernames/users"
    local payload="{\"usernames\": [\"$username\"]}"

    user_id=$(curl -s -X POST "$url" -H "Content-Type: application/json" -d "$payload" | jq -r '.data[0].id')

    if [[ "$user_id" == "null" || -z "$user_id" ]]; then
        echo -e "${RED}Error: Unable to fetch user ID for username $username${RESET}"
        exit 1
    fi

    echo "$user_id"
}

# Function to filter by date
filter_by_date() {
    local model_date="$1"
    local filter_date="$2"

    # Remove dashes from model date to simplify comparison
    model_date=$(echo "$model_date" | sed 's/-//g')

    # Depending on the date format passed, compare the year, year-month, or year-month-day
    if [[ "${#filter_date}" -eq 4 ]]; then
        # Year format (yyyy)
        if [[ ${model_date:0:4} == "$filter_date" ]]; then
            return 0
        fi
    elif [[ "${#filter_date}" -eq 7 ]]; then
        # Year-Month format (yyyy-mm)
        if [[ ${model_date:0:6} == "$filter_date" ]]; then
            return 0
        fi
    elif [[ "${#filter_date}" -eq 10 ]]; then
        # Year-Month-Day format (yyyy-mm-dd)
        if [[ ${model_date:0:8} == "$filter_date" ]]; then
            return 0
        fi
    fi

    return 1
}

# Function to fetch models for a user ID
get_user_models() {
    local user_id="$1"
    local api_url="https://inventory.roblox.com/v2/users/$user_id/inventory?assetTypes=Model&limit=100&sortOrder=Desc"
    local cursor=""
    local has_next=true

    echo -e "${GREEN}Fetching models for user ID: $user_id${RESET}"

    # Loop through the pages
    while $has_next; do
        if [[ -z "$cursor" ]]; then
            response=$(curl -s "$api_url")
        else
            response=$(curl -s "$api_url&cursor=$cursor")
        fi

        has_next=$(echo "$response" | jq -r '.nextPageCursor != null')
        cursor=$(echo "$response" | jq -r '.nextPageCursor')

        # Directly process and print the models
        echo "$response" | jq -r '.data[] | "\(.name) - \(.assetId) - \(.created)"' |
        while IFS= read -r line; do
            model_name=$(echo "$line" | awk -F' - ' '{print $1}')
            model_url="https://www.roblox.com/library/$(echo "$line" | awk -F' - ' '{print $2}')"
            model_date=$(echo "$line" | awk -F' - ' '{print $3}' | cut -d'T' -f1)

            # Filter by date if provided
            if [[ -n "$filter_date" ]]; then
                if ! filter_by_date "$model_date" "$filter_date"; then
                    continue
                fi
            fi

            # Print the model name and URL
            echo -e "[+] ${CYAN}$model_name${RESET} ~ { ${MAGENTA}$model_url${RESET} }"
        done
    done
}

# Main script
filter_date=""  # Default date filter (empty means no filter)

# Parse command-line options
while getopts "d:" opt; do
    case "$opt" in
        d)
            filter_date="$OPTARG"
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 [-d <date> (yyyy, yyyy-mm, yyyy-mm-dd)] <username>${RESET}"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
    echo -e "${YELLOW}Usage: $0 [-d <date>] <username>${RESET}"
    exit 1
fi

USERNAME="$1"
USER_ID=$(get_user_id "$USERNAME")
get_user_models "$USER_ID"

exit 0  # Ensure the script exits after processing the requested models
