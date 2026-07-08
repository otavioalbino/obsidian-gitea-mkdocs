#!/bin/bash

# ==============================================================================
# Script Name:  sync-local-wikis.sh
# Description:  Client-side script to automatically discover, clone, or update
#               all Markdown/Wiki repositories from a Gitea Organization.
# License:      MIT
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration & Environment Variables ---
# Customize these values to match your infrastructure requirements
GITEA_URL="https://gitea.yourdomain.com"
ORG_NAME="your-organization"
DEST_DIR="$HOME/Obsidian-Vaults"
TOKEN=$1

# Terminal output color definitions
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Validation: Ensure the Gitea personal access token was provided as an argument
if [ -z "$TOKEN" ]; then
    echo -e "${RED}[-] Error: Missing Gitea Access Token.${NC}"
    echo "Usage: ./sync-local-wikis.sh <YOUR_GITEA_TOKEN>"
    exit 1
fi

# --- Step 1: Initialize Workspace Directory ---
# Ensure the central vault folder exists in the user's home path
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

echo -e "${GREEN}[+] Fetching repository list from organization: ${ORG_NAME}...${NC}"

# --- Step 2: Query Gitea API for Repositories ---
# Force a hardcoded limit of 100 entries per page to avoid early API pagination truncation
REPOS=$(curl -s "$GITEA_URL/api/v1/orgs/$ORG_NAME/repos?access_token=$TOKEN&limit=100" | jq -r '.[].name')

# Check if the API response returned valid repository names
if [ -z "$REPOS" ] || [ "$REPOS" == "null" ]; then
    echo -e "${RED}[-] Error: Unable to fetch repository list. Check your URL, Token, or Organization name.${NC}"
    exit 1
fi

# --- Step 3: Iterate and Sync Each Repository ---
for REPO_NAME in $REPOS; do
    
    # EXCLUSION FILTERS: Define repositories that should NOT be synced into the local vault
    # Edit or add patterns matching internal architectures (e.g., system web portals, templates)
    if [[ "$REPO_NAME" == "main-portal" ]] || [[ "$REPO_NAME" == "base-template" ]] || [[ "$REPO_NAME" == IGNORE-* ]]; then
        echo -e "${YELLOW}[!] Skipping filtered repository: $REPO_NAME${NC}"
        continue
    fi

    # Build the authenticated Git HTTPS clone URL embedding the user token securely
    # Dynamic domain parsing isolates the raw host string from the GITEA_URL variable
    DOMAIN_HOST=$(echo "$GITEA_URL" | sed -e 's|^[^/]*//||')
    AUTH_CLONE_URL="https://$TOKEN@$DOMAIN_HOST/$ORG_NAME/$REPO_NAME.git"

    # --- Step 4: Clone New or Pull Existing Repositories ---
    if [ -d "$REPO_NAME" ]; then
        echo -e "${YELLOW}[+] Updating existing local wiki: $REPO_NAME...${NC}"
        cd "$REPO_NAME"
        
        # Pull incoming shifts discarding local uncommitted structural drift conflicts
        git pull --force
        cd ..
    else
        echo -e "${CYAN}[+] Cloning new wiki configuration: $REPO_NAME...${NC}"
        git clone "$AUTH_CLONE_URL"
    fi
done

# --- Step 5: Finalization Notification ---
echo -e "\n${GREEN}========================================================================${NC}"
echo -e "${GREEN} Success! All authorized organization wikis are ready at:${NC}"
echo -e "${GREEN} -> $DEST_DIR${NC}"
echo -e "${GREEN}========================================================================${NC}"
