#!/bin/bash

# ==============================================================================
# Script Name:  webhook-builder.sh
# Description:  Server-side webhook handler for automating MkDocs builds
#               triggered by Gitea repository pushes.
# License:      MIT
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration & Environment Variables ---
# Modify these paths on your server deployment as needed
BASE_DIR="/opt/mkdocs-gitea-wiki"
WEB_ROOT="/var/www/html/wiki"
VENV_PATH="$BASE_DIR/venv-mkdocs"
PORTAL_MAIN_DIR="$BASE_DIR/main-portal"

# --- Input Arguments from Gitea Webhook Payload ---
# Gitea passes the repository name as the first argument
REPO_NAME=$1

if [ -z "$REPO_NAME" ]; then
    echo "[-] Error: Repository name argument is missing."
    exit 1
fi

echo "[+] Starting automated build pipeline for repository: $REPO_NAME"

# --- Concurrency Control (Lock Mechanism) ---
# Prevents race conditions if multiple team members push simultaneously
LOCK_FILE="/tmp/mkdocs_build.lock"
exec 200>"$LOCK_FILE"

echo "[+] Acquiring deployment lock..."
if ! flock -n 200; then
    echo "[!] Another build process is currently running. Waiting for lock..."
    flock 200
fi
echo "[+] Lock acquired successfully."

# --- Step 1: Handle Specific Wiki Deletion or Update ---
# Check if this execution is for the main hub portal or an individual wiki repo
if [ "$REPO_NAME" != "main-portal" ]; then
    
    REPO_DIR="$BASE_DIR/$REPO_NAME"
    SYMLINK_TARGET="$PORTAL_MAIN_DIR/docs/$REPO_NAME"
    
    # If the repository folder exists, sync and update it
    if [ -d "$REPO_DIR" ]; then
        echo "[+] Syncing repository updates..."
        cd "$REPO_DIR"
        git fetch --all
        git reset --hard origin/main || git reset --hard origin/master
        
        # Ensure the symlink exists in the main portal structure
        if [ ! -L "$SYMLINK_TARGET" ]; then
            echo "[+] Creating missing symlink for $REPO_NAME..."
            ln -s "$REPO_DIR" "$SYMLINK_TARGET"
        fi
    else
        # If the repository directory doesn't exist, it means it was deleted
        echo "[!] Repository folder not found. Treating action as DELETION."
        echo "[+] Cleaning up stale symlinks and production build for: $REPO_NAME"
        rm -f "$SYMLINK_TARGET"
        rm -rf "$WEB_ROOT/$REPO_NAME"
    fi
else
    # If the push happened directly on the main hub structure
    echo "[+] Updating Main Portal structure..."
    cd "$PORTAL_MAIN_DIR"
    git fetch --all
    git reset --hard origin/main || git reset --hard origin/master
fi

# --- Step 2: Trigger MkDocs Rebuild ---
echo "[+] Activating Python Virtual Environment..."
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
else
    echo "[-] Error: Virtual environment not found at $VENV_PATH"
    exit 1
fi

echo "[+] Building static site with MkDocs..."
cd "$PORTAL_MAIN_DIR"

# Standard non-root build command leveraging group permissions (e.g., www-data)
# --clean removes stale files from the output directory
mkdocs build --clean -d "$WEB_ROOT"

echo "[+] Build pipeline completed successfully for $REPO_NAME!"

# --- Lock Release ---
# Lock is automatically released when the script terminates, but explicit is better
flock -u 200
