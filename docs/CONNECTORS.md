# Social Data Connectors

This document describes authentication requirements and configuration for each social data connector.

## Hacker News

**Status**: ✅ Implemented
**Authentication**: None required (public API)
**API Docs**: https://github.com/HackerNews/API

### Configuration

Edit `config/social_sources.yml`:
```yaml
hackernews:
  enabled: true
  endpoints:
    top: true      # Top stories
    new: false     # New stories
  max_posts: 200
```

### How to Disable

Set `enabled: false` in config.

---

## Reddit

**Status**: ✅ Implemented
**Authentication**: OAuth2 (client credentials)
**API Docs**: https://www.reddit.com/dev/api/

### Required Environment Variables

```bash
export REDDIT_CLIENT_ID="your-client-id"
export REDDIT_SECRET="your-client-secret"
export REDDIT_USER_AGENT="your-app-name/1.0"
```

### Setup Instructions

1. Go to https://www.reddit.com/prefs/apps
2. Click "create another app"
3. Select "script" type
4. Note your client ID (under app name) and secret
5. Set environment variables before running

### Configuration

Edit `config/social_sources.yml`:
```yaml
reddit:
  enabled: true
  subreddits:
    - programming
    - webdev
    - productmanagement
  max_posts: 200
  auth: env
```

### How to Disable

- Set `enabled: false` in config, OR
- Unset environment variables

If env vars are missing, Reddit will be automatically skipped with a warning.

---

## Twitter/X

**Status**: ⬜ Not Implemented (stub only)
**Authentication**: OAuth2 Bearer Token
**API Docs**: https://developer.twitter.com/en/docs/twitter-api

### Required Environment Variables

```bash
export X_BEARER="your-bearer-token"
```

### Setup Instructions

1. Apply for Twitter/X API access at https://developer.twitter.com
2. Create a project and app
3. Generate a Bearer Token
4. Set environment variable

### Configuration

Edit `config/social_sources.yml`:
```yaml
twitter:
  enabled: true  # Change from false to true
  note: "Requires X API v2 bearer token in env: X_BEARER"
```

### Implementation Status

Currently a stub. To implement:
- Create `R/13_twitter_pull.R`
- Use Twitter API v2 endpoints
- Respect rate limits (450 requests/15min for search)
- Add to orchestrator in `R/10_social_pull.R`

---

## LinkedIn

**Status**: ⬜ Not Implemented (stub only)
**Authentication**: Official LinkedIn API or manual export
**API Docs**: https://learn.microsoft.com/en-us/linkedin/

### Important Notes

⚠️ **Do NOT scrape LinkedIn**. Use only:
- Official LinkedIn API (requires partnership)
- Manual data export (GDPR request)
- Third-party authorized integrations

### Configuration

Edit `config/social_sources.yml`:
```yaml
linkedin:
  enabled: false
  note: "Use official partner/API or manual export; no scraping allowed"
```

### Implementation Status

Not implemented. LinkedIn has strict Terms of Service against scraping. Implementation requires:
- LinkedIn partnership or Marketing API access
- OAuth2 implementation
- Compliance review

---

## Adding New Connectors

To add a new data source:

1. Create `R/1X_sourcename_pull.R` with a `pull_sourcename(config)` function
2. Return data.frame with schema: `entity | source | meta_data | text`
3. Add configuration to `config/social_sources.yml`
4. Source the connector in `R/10_social_pull.R` and call it in the orchestrator
5. Update this documentation
6. Add tests if applicable

### Normalization Schema

All connectors must return a data.frame with exactly these columns:

- **entity** (character): Stable post ID
- **source** (character): Source name (lowercase, no spaces)
- **meta_data** (character): JSON string with at minimum:
  - `url`, `author`, `created_utc` (ISO-8601), `score`, `num_comments`, `reactions`, `origin`
- **text** (character): Title + " — " + body (or just title if no body)

Use `NA` or `null` for missing fields.

---

## Rate Limits & Best Practices

- **Hacker News**: No published limits; use small delays (50ms) between requests
- **Reddit**: 60 requests/minute for OAuth apps; built-in 1-second delays
- **Twitter/X**: 450 requests/15min for search; track usage carefully
- **LinkedIn**: Varies by API tier; consult documentation

Always:
- Respect `robots.txt` and Terms of Service
- Use appropriate User-Agent headers
- Implement exponential backoff for rate limit errors
- Cache results when possible
- Only collect public data

---

## Troubleshooting

### "connector: disabled (missing ENV_VAR)"

Solution: Export the required environment variable(s) before running.

### HTTP 401 Unauthorized

Solution: Check credentials are correct and not expired.

### HTTP 429 Too Many Requests

Solution: You've hit rate limits. Wait and retry with longer delays.

### "Too few rows; check API config or rate limits"

Solution:
- Verify config settings (max_posts, endpoints, subreddits)
- Check for API errors in logs
- Ensure at least one connector is enabled and working
- Increase max_posts if needed

---

Last updated: 2025-10-01
