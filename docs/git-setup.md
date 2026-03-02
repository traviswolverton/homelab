# Git Setup Guide

Getting this repo live on GitHub.

## One-time setup (on your Proxmox host or admin machine)

### 1. Install git

```bash
apt-get install git
```

### 2. Configure your identity

```bash
git config --global user.name "Travis Wolverton"
git config --global user.email "your@gmail.com"
```

### 3. Generate an SSH key for GitHub

```bash
ssh-keygen -t ed25519 -C "your@gmail.com"
# Accept defaults (Enter × 3)

# Copy the public key
cat ~/.ssh/id_ed25519.pub
```

### 4. Add the key to GitHub

1. Go to https://github.com/settings/keys
2. Click **New SSH key**
3. Paste the output from step 3
4. Title it something like "proxmox-host"

### 5. Test the connection

```bash
ssh -T git@github.com
# Should say: Hi traviswolverton! You've successfully authenticated...
```

---

## Initialize and push this repo

```bash
# Navigate to where you've put the homelab folder
cd /opt/homelab   # or wherever you place it

# Initialize git
git init

# Set the default branch name
git branch -M main

# Add all files
git add .

# First commit
git commit -m "initial commit: homelab configs, scripts, and docs"

# Add GitHub as remote
git remote add origin git@github.com:traviswolverton/homelab.git

# Push
git push -u origin main
```

> First, create the repo on GitHub: https://github.com/new
> Name it `homelab`, set to **Private**, **don't** initialize with README.

---

## Day-to-day workflow

After you edit a script or doc:

```bash
# See what changed
git diff

# Stage your changes
git add .
# or stage a specific file:
git add scripts/monitoring/premiumize-fairuse.sh

# Commit with a descriptive message
git commit -m "premiumize: lower high threshold from 500 to 400"

# Push to GitHub
git push
```

## Useful commands

```bash
git log --oneline        # see commit history
git diff                 # see unstaged changes
git status               # see what's staged/unstaged
git checkout -- <file>   # discard changes to a file (careful!)
```

---

## Future: Migrate to Gitea on RPi

When you're ready:

```bash
# Install Gitea on RPi, create repo, then:
git remote add gitea http://<rpi-ip>:3000/traviswolverton/homelab.git
git push gitea --mirror

# Switch primary remote to Gitea
git remote set-url origin http://<rpi-ip>:3000/traviswolverton/homelab.git

# Keep GitHub as backup (push to both)
git remote set-url --add origin git@github.com:traviswolverton/homelab.git

# Now `git push` goes to both automatically
```
