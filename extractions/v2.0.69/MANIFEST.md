# Extraction Manifest v2.0.69

Source: `@anthropic-ai/claude-code@2.0.69`
Extracted: 2024-12-14
CLI.js size: ~11MB (formatted)

## Changes from v2.0.58

### New Beta Flag
- `advanced-tool-use-2025-11-20`

### New Endpoint
- `POST /v1/token` - CreateOAuth2Token (SDK command)

### New URLs
- `https://claude.ai/admin-settings/usage`
- `https://platform.claude.com/llms.txt`
- `https://github.com/anthropics/claude-code-marketplace/blob/main/plugins/code-review/README.md`
- `https://slack.com/marketplace/A08SF47R6P4-claude`

### Changed URLs
- JetBrains docs: `https://docs.claude.com/s/claude-code-jetbrains` (was code.claude.com)

### Obfuscation Changes
- HTTP client: `YQ` → `wQ`
- Stainless version var: `gp` → `Wc`

## Verification

```bash
# Re-extract from source
npm pack @anthropic-ai/claude-code@2.0.69
tar -xzf anthropic-ai-claude-code-2.0.69.tgz
cd package && npx prettier --write cli.js
```

## Raw Extractions

| File | Lines | Content |
|------|-------|---------|
| urls.txt | 278 | All hardcoded URLs |
| paths.txt | 13 | API path literals |
| headers.txt | 19 | HTTP header names |
| beta_flags.txt | 13 | Beta feature flags |
| scopes.txt | 4 | OAuth scopes |
| http_methods.txt | 4 | HTTP method counts |
| axios_methods.txt | 5 | Axios call counts |

## Call Contexts

31 files with `-B 10 -A 20` context around each endpoint pattern.

### OAuth Flow
- `oauth-token-exchange.txt` - `grant_type.*authorization_code`
- `oauth-refresh.txt` - `grant_type.*refresh_token`

### NEW in v2.0.69
- `v1-token.txt` - `/v1/token` CreateOAuth2Token endpoint

### Anthropic API (/api/*)
- `api-oauth-profile.txt` - `/api/oauth/profile`
- `api-oauth-usage.txt` - `/api/oauth/usage`
- `api-oauth-account-settings.txt` - `/api/oauth/account/settings`
- `api-oauth-grove-notice.txt` - `grove_notice_viewed`
- `api-oauth-create-api-key.txt` - `create_api_key`
- `api-oauth-roles.txt` - `claude_cli/roles`
- `api-oauth-client-data.txt` - `client_data`
- `api-grove-settings.txt` - `api/claude_code_grove`
- `api-first-token-date.txt` - `first_token_date`
- `api-sonnet-1m-access.txt` - `sonnet_1m_access`
- `api-referral.txt` - `referral`
- `api-hello.txt` - `/api/hello`
- `api-feedback.txt` - `claude_cli_feedback`
- `api-metrics.txt` - `api/claude_code/metrics`
- `api-metrics-enabled.txt` - `metrics_enabled`
- `api-event-logging.txt` - `event_logging/batch`
- `api-link-vcs.txt` - `link_vcs_account`
- `api-github-repos.txt` - `code/repos`
- `api-domain-info.txt` - `domain_info`

### SDK API (/v1/*)
- `v1-messages.txt` - `"/v1/messages"`
- `v1-count-tokens.txt` - `count_tokens`
- `v1-files.txt` - `"/v1/files"`
- `v1-models.txt` - `"/v1/models"`
- `v1-skills.txt` - `skills?beta=true`
- `v1-batches.txt` - `messages/batches`
- `v1-sessions.txt` - `/v1/sessions`
- `v1-session-ingress.txt` - `session_ingress`
- `v1-environment-providers.txt` - `environment_providers`
- `v1-token.txt` - `/v1/token` (NEW)

## Key Constants

```
CLIENT_ID: 9d1c250a-e61b-44d9-88ed-5944d1962f5e
STAINLESS_VERSION: 0.70.0
API_VERSION: 2023-06-01
HTTP_CLIENT: wQ (was YQ in v2.0.58)
```

## Beta Flags

```
advanced-tool-use-2025-11-20  (NEW)
bedrock-2023-05-31
context-management-2025-06-27
files-api-2025-04-14
interleaved-thinking-2025-05-14
message-batches-2024-09-24
oauth-2025-04-20
skills-2025-10-02
structured-outputs-2025-09-17
token-counting-2024-11-01
tool-examples-2025-10-29
vertex-2023-10-16
web-search-2025-03-05
```

## OAuth Scopes

```
org:create_api_key
user:inference
user:profile
user:sessions:claude_code
```

## HTTP Methods Summary

| Method | SDK Count | Axios Count |
|--------|-----------|-------------|
| POST | 33 | 15 |
| GET | 10 | 34 |
| PUT | 2 | 1 |
| PATCH | - | 1 |
| DELETE | 1 | - |
| HEAD | - | 2 |
