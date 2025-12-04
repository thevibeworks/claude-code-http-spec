# Claude Code - Complete API Endpoint Reference

**Last Updated**: 2025-10-22
**Package Version**: 2.0.25
**Source**: Extracted from `package/cli.js` and runtime logs

---

## 📋 Table of Contents

- [OAuth & Authentication](#oauth--authentication)
- [User Profile & Settings](#user-profile--settings)
- [Usage & Quota](#usage--quota)
- [Session Management](#session-management)
- [Organization](#organization)
- [Telemetry & Feedback](#telemetry--feedback)
- [Messages API (Standard)](#messages-api-standard)
- [Files API](#files-api)
- [Models API](#models-api)
- [Grove (Data Sharing)](#grove-data-sharing)
- [Health Check](#health-check)
- [Console/Web](#consoleweb)

---

## OAuth & Authentication

### 1. OAuth Authorize (Console)
```
GET https://console.anthropic.com/oauth/authorize
```
**Purpose**: Initiate OAuth flow for Console authentication
**Used**: User login flow
**Auth**: None (public)
**Customization Potential**: ⭐ Low - Standard OAuth

### 2. OAuth Authorize (Claude.ai)
```
GET https://claude.ai/oauth/authorize
```
**Purpose**: Initiate OAuth flow for Claude.ai authentication
**Used**: Alternative login flow
**Auth**: None (public)
**Customization Potential**: ⭐ Low - Standard OAuth

### 3. OAuth Token
```
POST https://console.anthropic.com/v1/oauth/token
```
**Purpose**: Exchange authorization code for access token
**Used**: Complete OAuth flow
**Auth**: Client credentials
**Customization Potential**: ⭐ Low - Standard OAuth

### 4. OAuth Hello (Health Check)
```
GET https://console.anthropic.com/v1/oauth/hello
```
**Purpose**: Verify OAuth service health
**Used**: Connection testing
**Auth**: None
**Customization Potential**: ⭐ Low - Health check only

### 5. Create API Key
```
POST https://api.anthropic.com/api/oauth/claude_cli/create_api_key
```
**Purpose**: Generate new API key from OAuth session
**Used**: Converting OAuth to API key
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐ **HIGH** - Could automate API key generation

### 6. Get Roles
```
GET https://api.anthropic.com/api/oauth/claude_cli/roles
```
**Purpose**: Fetch user's role/permissions in organization
**Used**: Authorization checks
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐ **HIGH** - Could build custom permission systems

---

## User Profile & Settings

### 7. OAuth Profile
```
GET https://api.anthropic.com/api/oauth/profile
```
**Purpose**: Get current user's profile information
**Used**: Display user info in CLI
**Auth**: OAuth Bearer token
**Scope**: `user:profile`
**Customization Potential**: ⭐⭐ Medium - User info for custom UIs

### 8. CLI Profile (Legacy?)
```
GET https://api.anthropic.com/api/claude_cli_profile
```
**Purpose**: Get CLI-specific profile data
**Used**: Unknown (possibly deprecated)
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐ Low - Unclear purpose

### 9. Account Settings
```
GET https://api.anthropic.com/api/oauth/account/settings
```
**Purpose**: Get user account settings
**Used**: CLI startup, fetch preferences
**Auth**: OAuth Bearer token
**Scope**: `user:profile`
**Customization Potential**: ⭐⭐⭐ **HIGH** - Could sync settings, modify preferences

### 10. Update Account Settings
```
PATCH https://api.anthropic.com/api/oauth/account/settings
Body: { "grove_enabled": true/false }
```
**Purpose**: Update account settings (e.g., Grove opt-in/out)
**Used**: When user changes settings
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐⭐ **VERY HIGH** - Automate settings management

### 11. Client Data
```
GET https://api.anthropic.com/api/oauth/claude_cli/client_data
```
**Purpose**: Get CLI client-specific data/config
**Used**: CLI startup (seen in logs)
**Auth**: OAuth Bearer token
**Response**: `{"client_data":{}}`
**Customization Potential**: ⭐⭐ Medium - Custom client config

---

## Usage & Quota

### 12. OAuth Usage (★ DISCOVERED)
```
GET https://api.anthropic.com/api/oauth/usage
```
**Purpose**: Get current rate limit utilization
**Used**: CLI startup, quota checking
**Auth**: OAuth Bearer token
**Scope**: `user:profile`
**Response**:
```json
{
  "five_hour": {
    "utilization": 60,
    "resets_at": "2025-10-22T11:00:00Z"
  },
  "seven_day": {
    "utilization": 92,
    "resets_at": "2025-10-23T01:00:00Z"
  },
  "seven_day_oauth_apps": null,
  "seven_day_opus": {
    "utilization": 0,
    "resets_at": null
  }
}
```
**Customization Potential**: ⭐⭐⭐⭐⭐ **EXCELLENT** - Build quota warnings, usage dashboards

---

## Session Management

### 13. Create Session
```
POST https://api.anthropic.com/api/oauth/organizations/{org_id}/code/sessions
```
**Purpose**: Create new Claude Code session
**Used**: Start new coding session
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐⭐ **VERY HIGH** - Custom session management, logging

### 14. Get Session
```
GET https://api.anthropic.com/api/oauth/organizations/{org_id}/code/sessions/{session_id}
```
**Purpose**: Retrieve existing session data
**Used**: Resume session, get history
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐⭐ **VERY HIGH** - Session analytics, history export

### 15. Update/Delete Session
```
PATCH/DELETE https://api.anthropic.com/api/oauth/organizations/{org_id}/code/sessions/{session_id}
```
**Purpose**: Modify or end session
**Used**: Session lifecycle management
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐ HIGH - Custom session cleanup

### 16. Resume Session
```
POST https://api.anthropic.com/api/oauth/organizations/{org_id}/code/sessions/{session_id}/resume
```
**Purpose**: Resume a paused/saved session
**Used**: /resume command
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐⭐ **VERY HIGH** - Custom session restore logic

---

## Organization

### 17. First Token Date
```
GET https://api.anthropic.com/api/organization/claude_code_first_token_date
```
**Purpose**: Get when organization first used Claude Code
**Used**: Onboarding, analytics
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐ Medium - Track adoption metrics

### 18. Recommended Subscription
```
GET https://api.anthropic.com/api/organization/{org_id}/claude_code_recommended_subscription
```
**Purpose**: Get subscription recommendations based on usage
**Used**: Upsell prompts
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐ Low - Billing specific

### 19. Data Sharing Settings
```
GET/PATCH https://api.anthropic.com/api/organizations/{org_id}/claude_code_data_sharing
```
**Purpose**: Manage org-wide data sharing preferences
**Used**: Privacy settings
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐⭐ HIGH - Automate compliance settings

### 20. Metrics Enabled Check
```
GET https://api.anthropic.com/api/claude_code/organizations/metrics_enabled
```
**Purpose**: Check if telemetry is enabled for org
**Used**: Before sending telemetry
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐ Medium - Custom telemetry control

---

## Telemetry & Feedback

### 21. Send Metrics
```
POST https://api.anthropic.com/api/claude_code/metrics
```
**Purpose**: Send usage metrics/telemetry
**Used**: Background telemetry
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐ Medium - Custom analytics

### 22. Submit Feedback
```
POST https://api.anthropic.com/api/claude_cli_feedback
```
**Purpose**: Submit bug reports/feedback
**Used**: /bug command
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐⭐ Medium - Custom feedback systems

---

## Grove (Data Sharing)

### 23. Grove Config
```
GET https://api.anthropic.com/api/claude_code_grove
```
**Purpose**: Get Grove (data sharing) configuration
**Used**: CLI startup
**Auth**: OAuth Bearer token
**Response**: Grove settings (enabled, domain excluded, notice info)
**Customization Potential**: ⭐⭐⭐ HIGH - Privacy management automation

### 24. Grove Notice Viewed
```
POST https://api.anthropic.com/api/oauth/account/grove_notice_viewed
```
**Purpose**: Mark Grove notice as viewed
**Used**: Dismiss notice
**Auth**: OAuth Bearer token
**Customization Potential**: ⭐ Low - UI state only

---

## Messages API (Standard)

### 25. Create Message
```
POST https://api.anthropic.com/v1/messages?beta=true
```
**Purpose**: Send message to Claude (main API)
**Used**: All AI interactions
**Auth**: OAuth Bearer token / API key
**Customization Potential**: ⭐⭐⭐⭐⭐ **EXCELLENT** - Core AI interaction

### 26. Count Tokens
```
POST https://api.anthropic.com/v1/messages/count_tokens?beta=true
```
**Purpose**: Count tokens without making API call
**Used**: Token estimation
**Auth**: OAuth Bearer token / API key
**Customization Potential**: ⭐⭐⭐⭐ **VERY HIGH** - Cost estimation, optimization

### 27. Create Message Batch
```
POST https://api.anthropic.com/v1/messages/batches?beta=true
```
**Purpose**: Create batch of messages for async processing
**Used**: Batch operations
**Auth**: API key
**Customization Potential**: ⭐⭐⭐⭐ **VERY HIGH** - Bulk processing

### 28. Get Batch Status
```
GET https://api.anthropic.com/v1/messages/batches/{batch_id}?beta=true
```
**Purpose**: Check batch processing status
**Used**: Monitor batch jobs
**Auth**: API key
**Customization Potential**: ⭐⭐⭐ HIGH - Batch job monitoring

### 29. Cancel Batch
```
POST https://api.anthropic.com/v1/messages/batches/{batch_id}/cancel?beta=true
```
**Purpose**: Cancel running batch
**Used**: Stop batch processing
**Auth**: API key
**Customization Potential**: ⭐⭐ Medium - Batch management

---

## Files API

### 30. Upload File
```
POST https://api.anthropic.com/v1/files
```
**Purpose**: Upload file for processing
**Used**: File attachments
**Auth**: API key
**Customization Potential**: ⭐⭐⭐ HIGH - Custom file handling

### 31. Get File
```
GET https://api.anthropic.com/v1/files/{file_id}
```
**Purpose**: Retrieve file metadata
**Used**: File management
**Auth**: API key
**Customization Potential**: ⭐⭐ Medium - File tracking

---

## Models API

### 32. List Models
```
GET https://api.anthropic.com/v1/models
```
**Purpose**: Get available models
**Used**: Model selection
**Auth**: API key
**Customization Potential**: ⭐⭐⭐ HIGH - Dynamic model selection

### 33. Get Model
```
GET https://api.anthropic.com/v1/models/{model_id}
```
**Purpose**: Get specific model details
**Used**: Model info
**Auth**: API key
**Customization Potential**: ⭐⭐ Medium - Model capabilities check

---

## Health Check

### 34. API Hello
```
GET https://api.anthropic.com/api/hello
```
**Purpose**: Health check / API availability
**Used**: Connection testing, startup
**Auth**: None
**Response**: `{"message":"hello"}`
**Customization Potential**: ⭐ Low - Simple health check

---

## Console/Web

### 35. Buy Credits
```
GET https://console.anthropic.com/buy_credits?returnUrl=/oauth/code/success%3Fapp%3Dclaude-code
```
**Purpose**: Redirect to credit purchase page
**Used**: Upsell flow
**Auth**: Session
**Customization Potential**: ⭐ Low - Billing UI

### 36. OAuth Success
```
GET https://console.anthropic.com/oauth/code/success?app=claude-code
```
**Purpose**: OAuth success redirect
**Used**: Complete OAuth flow
**Auth**: None
**Customization Potential**: ⭐ Low - OAuth callback

### 37. Domain Info
```
GET https://api.anthropic.com/api/web/domain_info
```
**Purpose**: Get domain/organization info
**Used**: Unknown (web-related)
**Auth**: Unknown
**Customization Potential**: ⭐ Low - Unclear purpose

---

## 🌟 Top Customization Opportunities

### Tier 1: Essential for Custom Workflows
1. **OAuth Usage** (`/api/oauth/usage`) - Build quota dashboards, warnings
2. **Account Settings** (`/api/oauth/account/settings`) - Automate preferences
3. **Session Management** (`/api/oauth/organizations/{}/code/sessions`) - Custom history, analytics
4. **Messages API** (`/v1/messages`) - Core AI interaction
5. **Count Tokens** (`/v1/messages/count_tokens`) - Cost optimization

### Tier 2: Advanced Customization
6. **Create API Key** (`/api/oauth/claude_cli/create_api_key`) - API key automation
7. **Get Roles** (`/api/oauth/claude_cli/roles`) - Permission systems
8. **Resume Session** (`/api/oauth/organizations/{}/code/sessions/{}/resume`) - Session restore
9. **Message Batches** (`/v1/messages/batches`) - Bulk operations
10. **Grove Config** (`/api/claude_code_grove`) - Privacy automation

### Tier 3: Nice to Have
11. **List Models** (`/v1/models`) - Dynamic model selection
12. **Data Sharing** (`/api/organizations/{}/claude_code_data_sharing`) - Compliance automation
13. **Files API** (`/v1/files`) - File handling
14. **Profile** (`/api/oauth/profile`) - User info

---

## 🔬 Testing Results

### ✅ Confirmed Working (from runtime logs)
- [x] `/api/oauth/usage` - ✅ Returns rate limit utilization (5h/7d windows)
- [x] `/api/oauth/account/settings` - ✅ Returns user settings (gzipped)
- [x] `/api/claude_code_grove` - ✅ Returns Grove privacy config (gzipped)
- [x] `/api/oauth/claude_cli/client_data` - ✅ Returns `{"client_data":{}}` (empty)
- [x] `/v1/messages/count_tokens` - ✅ Returns token count estimation
- [x] `/v1/messages` - ✅ Core AI interaction, returns streaming/JSON
- [x] `/api/hello` - ✅ Health check, returns `{"message":"hello"}`

### 📋 Immediate Testing Priority (High Value)
- [ ] `/api/oauth/claude_cli/roles` - Permission model
- [ ] `/api/oauth/organizations/{}/code/sessions` - Session API
- [ ] `/api/oauth/profile` - User data structure

### 🔍 Secondary Testing (Good to Know)
- [ ] `/api/oauth/claude_cli/create_api_key` - Key generation
- [ ] `/v1/models` - Available models list
- [ ] `/api/organization/claude_code_first_token_date` - Date format

### 📝 Low Priority (Nice to Have)
- [ ] `/api/claude_code/metrics` - Telemetry format
- [ ] `/api/organizations/{}/claude_code_data_sharing` - Data sharing settings

---

## 📝 Notes

1. **BASE_API_URL**: Defaults to `https://api.anthropic.com` but can be configured
2. **OAuth Scopes**: Most endpoints require `user:profile` and/or `user:inference`
3. **Beta Flag**: Many endpoints use `?beta=true` for preview features
4. **Organization ID**: Required for session endpoints, obtained from auth context
5. **Rate Limits**: Headers include `anthropic-ratelimit-*` for tracking
6. **Compression**: Responses are typically gzip-encoded

---

## 🔗 Related Files

- **`ENDPOINT-TESTING-REPORT.md`** - Comprehensive testing results from runtime logs ⭐
- `test-usage-api.sh` - Test script for usage endpoint (working)
- `claude-code-usage-api-report.org` - Detailed usage API documentation
- `USAGE-API-README.md` - Quick reference
- `log-2025-10-22-06-13-23.jsonl` - Real API call logs (source data)

---

## 🚀 Next Steps

1. Test high-value endpoints systematically
2. Document request/response formats for each
3. Build wrapper scripts for common operations
4. Create custom CLI tools using these APIs
5. Automate workflows (quota monitoring, session management, etc.)

---

**Total Endpoints Discovered**: 37+
**Tested**: 7 (confirmed working from runtime logs)
**High Customization Potential**: 10
**Status**: Testing in progress - See ENDPOINT-TESTING-REPORT.md for detailed results
