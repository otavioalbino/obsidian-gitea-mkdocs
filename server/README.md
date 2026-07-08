# Client-Side Synchronization Automation

This directory contains the client-side synchronization script used to keep local Obsidian workspaces aligned with the repositories hosted on Gitea.

## Overview

In environments where documentation is distributed across multiple repositories, manually cloning and updating each repository becomes difficult to maintain.

The `sync-local-wikis.sh` script automates repository discovery and synchronization by querying the Gitea API and updating the local workspace.

## Workflow

The script performs the following steps:

1. **Initialize the workspace**

   Ensures that the target workspace directory (for example, `$HOME/Obsidian-Vaults`) exists.

2. **Discover repositories**

   Retrieves the list of repositories from the Gitea API (`/api/v1/orgs/{org}/repos`) using a Personal Access Token.

3. **Filter repositories**

   Excludes repositories that should not be synchronized locally, such as templates or administrative repositories.

4. **Synchronize repositories**

   - If a repository does not exist locally, it is cloned.
   - If the repository already exists, it is updated using `git pull --force`.

## Usage

### Generate a Personal Access Token

In Gitea:

1. Open **Settings → Applications**.
2. Generate a Personal Access Token with permission to access the required repositories.

### Run the script

```bash
chmod +x sync-local-wikis.sh
./sync-local-wikis.sh <PERSONAL_ACCESS_TOKEN>
```

The script can be executed manually or scheduled using a task scheduler such as `cron` on Linux/macOS or Task Scheduler on Windows (for example, through WSL).
