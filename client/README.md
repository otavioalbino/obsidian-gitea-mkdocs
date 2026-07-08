# Client-Side Synchronization Automation

This folder contains the automation layer designed to run locally on the content authors' machines.

## Why Do We Need This Script?

In a multi-repository wiki architecture, an organization might scale to dozens of individual Git repositories (one for each project, department, or knowledge base). Managing this inside Obsidian manually introduces major friction:
1. **Onboarding overhead:** New team members would have to manually clone every single repository.
2. **Structural Drift:** If a administrator creates a new wiki repository on Gitea, users wouldn't know unless notified manually.
3. **Frictionless workflow:** This script bridge the gap, turning Obsidian into a centralized, auto-updating knowledge hub without requiring deep Git knowledge from the writers.

## How It Works

The `sync-local-wikis.sh` script automates workspace discovery and orchestration using the following lifecycle:

1. **Workspace Initialization:** It ensures a centralized directory (e.g., `$HOME/Obsidian-Vaults`) exists on the host machine.
2. **API Discovery:** It queries the Gitea API (`/api/v1/orgs/{org}/repos`) using a Personal Access Token to map all live repositories under your Organization in real-time.
3. **Filtering:** It filters out administrative or system repositories (like templates or central portals) that shouldn't be rendered as standalone user vaults.
4. **Idempotent Sync:**
   * If a repository **does not exist** locally, the script performs a secure, authenticated `git clone`.
   * If the repository **already exists**, it executes a `git pull --force` to rapidly sync incoming upstream documentation changes, bypassing minor local structural conflicts.

## Usage Instructions

1. **Generate a Gitea Token:** Go to your Gitea settings > Applications > Generate New Token.
2. **Execute the Script:** Run the script passing your token as the first argument:
   ```bash
   chmod +x sync-local-wikis.sh
   ./sync-local-wikis.sh YOUR_GITEA_PERSONAL_ACCESS_TOKEN
    ```

   Note: You can easily pair this script with a local cronjob (Linux/macOS) or Task Scheduler (Windows via WSL) to keep your Obsidian vaults constantly synchronized in the background.
