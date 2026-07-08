# Base Wiki Template & Obsidian Configuration

This directory contains the template used when creating new wiki repositories in Gitea. It includes the initial file structure and the recommended Obsidian configuration for compatibility with the documentation pipeline.

## Repository Structure

Each repository created from this template should contain at least:

- `index.md`: Entry point for the documentation.

Additional files and directories can be added as needed.

## Obsidian Configuration

The following settings are recommended for repositories generated from this template.

### 1. Link format

Configure Obsidian to generate standard Markdown links.

- Open **Settings → Files and links**.
- Disable **Use [[WikiLinks]]**.
- Set **Default link format** to **Relative path to file**.

This produces relative Markdown links such as:

```md
[My Document](My-Document.md)
```

### 2. Attachments

Store attachments in a dedicated directory.

1. Create an `attachments` directory in the repository.
2. Open **Settings → Files and links**.
3. Set **Default location for new attachments** to **In the folder specified below**.
4. Select the `attachments` directory.

### 3. Obsidian Git

Install the **Obsidian Git** community plugin if automatic synchronization is required.

Typical configurations include:

- Enabling periodic backups (for example, every 15 or 30 minutes).
- Assigning a keyboard shortcut to trigger synchronization manually.

## Using the Template in Gitea

1. Create a repository named `obsidian-template-base`.
2. Add the contents of this directory, including `index.md` and the `.obsidian` configuration.
3. Open **Repository Settings** and enable **Template Repository**.
4. Create new wiki repositories from this template when needed.
