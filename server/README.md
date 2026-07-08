# Server-Side Webhook Automation & Deployment

This directory contains the server-side automation responsible for handling Gitea webhook events and executing MkDocs builds.

## Overview

When documentation is pushed from Obsidian to Gitea, the changes are stored only in the Git repository. To publish the updated documentation, the server receives the webhook event, synchronizes the local repository, and generates the static site using MkDocs.

The automation also handles situations such as:

- Multiple webhook requests arriving simultaneously.
- Removal of repositories that are no longer available in Gitea.

## Workflow

The `webhook-builder.sh` script performs the following steps:

1. **Acquire an exclusive lock**

   An exclusive lock is created using `flock` (`/tmp/mkdocs_build.lock`). If another build is already running, subsequent executions wait until the current process finishes.

2. **Synchronize repositories**

   - For existing repositories, the script performs a `git reset --hard` followed by the required synchronization steps. It also ensures that the repository is available through the appropriate symbolic link inside the MkDocs `docs/` directory.
   - If a repository no longer exists in Gitea, the corresponding symbolic link and generated HTML output are removed.

3. **Activate the Python virtual environment**

   The script activates the dedicated virtual environment (`venv-mkdocs`) before executing MkDocs. This isolates project dependencies from the system-wide Python installation.

4. **Build the documentation**

   The documentation is generated using:

   ```bash
   mkdocs build --clean
   ```

   The generated files are written to the configured web directory (for example, `/var/www/html/wiki`).

## Deployment

### 1. Install dependencies

Install the required packages and create the application directories.

```bash
sudo apt update
sudo apt install git python3 python3-pip python3-venv jq -y

sudo mkdir -p /opt/mkdocs-gitea-wiki
sudo mkdir -p /var/www/html/wiki

sudo chown -R $USER:www-data /opt/mkdocs-gitea-wiki /var/www/html/wiki
```

### 2. Create the Python virtual environment

```bash
cd /opt/mkdocs-gitea-wiki

python3 -m venv venv-mkdocs
source venv-mkdocs/bin/activate

pip install mkdocs \
    mkdocs-awesome-pages-plugin \
    mkdocs-roamlinks-plugin
```

### 3. Configure the Gitea webhook

Configure a webhook that sends push events to the server responsible for executing `webhook-builder.sh`.

In Gitea:

1. Open **Settings → Webhooks** for the repository or organization.
2. Select **Add Webhook → Gitea**.
3. Configure:

| Setting | Value |
|---------|-------|
| Target URL | `http://<SERVER_IP>:<LISTENER_PORT>/webhook` |
| HTTP Method | `POST` |
| Content Type | `application/json` |
| Trigger | `Push Events` |

4. Save the webhook.

Whenever a push event is received, the listener invokes `webhook-builder.sh`, which synchronizes the repositories and rebuilds the MkDocs site.
