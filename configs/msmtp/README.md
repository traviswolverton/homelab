# msmtp Gmail Configuration

Used by all maintenance scripts to send email reports.

## Install

```bash
apt-get install msmtp msmtp-mta
```

## Config file: `/etc/msmtprc`

```ini
# /etc/msmtprc
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account gmail
host           smtp.gmail.com
port           587
from           your@gmail.com
user           your@gmail.com
password       YOUR_APP_PASSWORD

account default : gmail
```

## Setup Notes

1. **App Password required** — Gmail requires an App Password (not your account password)
   - Google Account → Security → 2-Step Verification → App passwords
   - Generate one for "Mail" / "Linux device"

2. **Set permissions** (config contains credentials):
   ```bash
   chmod 600 /etc/msmtprc
   ```

3. **Test:**
   ```bash
   echo "Test from homelab" | msmtp -a gmail your@gmail.com --subject="test"
   ```

## Usage in scripts

```bash
# Simple send
echo "Body text" | msmtp -a gmail your@gmail.com --subject="Subject"

# Multiline body
echo -e "Line 1\nLine 2\nLine 3" | msmtp -a gmail your@gmail.com --subject="Subject"
```

## Log location

`/var/log/msmtp.log` — check here if emails aren't arriving.
