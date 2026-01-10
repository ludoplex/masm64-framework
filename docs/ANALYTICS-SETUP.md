# Analytics Email Setup

The MASM64 Framework includes a weekly analytics report sent via email.

## Recipients

- **To**: vincentlanderson@mightyhouseinc.com
- **CC**: rachelwilliams@mightyhouseinc.com

## Schedule

Reports are sent every **Monday at 9:00 AM UTC**.

## Required GitHub Secrets

To enable email reports, set the following secrets in your repository:

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Add these repository secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SMTP_SERVER` | SMTP server address | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USERNAME` | SMTP username/email | `noreply@example.com` |
| `SMTP_PASSWORD` | SMTP password or app password | `xxxx-xxxx-xxxx-xxxx` |

## SMTP Provider Options

### Zoho Mail (Recommended)
- Server: `smtp.zoho.com`
- Port: `587` (TLS) or `465` (SSL)
- Username: Your full Zoho email address
- Password: Your Zoho password or App-Specific Password

**Zoho Setup Steps:**
1. Go to Zoho Mail > Settings > Security > App Passwords
2. Generate an App-Specific Password for "GitHub Actions"
3. Use that password as `SMTP_PASSWORD`

| Secret | Zoho Value |
|--------|------------|
| `SMTP_SERVER` | `smtp.zoho.com` |
| `SMTP_PORT` | `587` |
| `SMTP_USERNAME` | `noreply@mightyhouseinc.com` |
| `SMTP_PASSWORD` | Your app-specific password |

### Gmail (with App Password)
- Server: `smtp.gmail.com`
- Port: `587`
- Requires 2FA enabled and App Password generated

### Microsoft 365
- Server: `smtp.office365.com`
- Port: `587`
- Username: Your email address
- Password: Your password or app password

## Manual Trigger

To send a report manually:
1. Go to **Actions** > **Weekly Analytics Report**
2. Click **Run workflow**
3. Select the branch and click **Run workflow**

## Report Contents

Each report includes:
- Page views and unique visitors (14-day traffic)
- Git clone statistics
- Stars, forks, and watchers count
- Open issues count
- Weekly activity (commits, issues, PRs)
- Top traffic referrers

