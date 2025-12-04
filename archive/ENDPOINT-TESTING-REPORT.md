# Claude Code API Endpoint Testing Report

**Date**: 2025-10-21
**Source**: Runtime logs (log-2025-10-22-06-13-23.jsonl)
**Purpose**: Document working endpoints discovered from actual CLI execution

---

## Summary

From analyzing actual CLI execution logs, we've confirmed **8 working endpoints** that provide valuable data for custom workflows. These were all successfully called during normal CLI startup and operation.

---

## ✅ Confirmed Working Endpoints

### 1. OAuth Usage API (Tier 1 - EXCELLENT)
```
GET https://api.anthropic.com/api/oauth/usage
```
**Status**: ✅ 200 OK (Line 10)
**Response Time**: ~820ms
**Auth**: OAuth Bearer token
**Headers**:
- `Authorization: Bearer sk-...rAAA`
- `anthropic-beta: oauth-2025-04-20`
- `Content-Type: application/json`
- `User-Agent: claude-code/2.0.25`

**Response** (gzipped):
```json
{
  "five_hour": {
    "utilization": 94,
    "resets_at": "2025-10-22T10:59:59.676000+00:00"
  },
  "seven_day": {
    "utilization": 95,
    "resets_at": "2025-10-23T00:59:59.676018+00:00"
  },
  "seven_day_oauth_apps": null,
  "seven_day_opus": {
    "utilization": 0,
    "resets_at": null
  }
}
```

**Customization Value**: ⭐⭐⭐⭐⭐
- Build quota warning systems
- Create usage dashboards
- Automate rate limit monitoring
- Implement intelligent request throttling

**Tested**: ✅ test-usage-api.sh works perfectly

---

### 2. Account Settings API (Tier 1 - HIGH)
```
GET https://api.anthropic.com/api/oauth/account/settings
```
**Status**: ✅ 200 OK (Line 5)
**Response Time**: ~730ms
**Auth**: OAuth Bearer token
**Headers**:
- `Authorization: Bearer sk-...rAAA`
- `anthropic-beta: oauth-2025-04-20`
- `User-Agent: claude-code/2.0.25`

**Response**: Gzipped JSON (structure not yet decoded)

**Customization Value**: ⭐⭐⭐⭐
- Sync user preferences across machines
- Automate settings backup/restore
- Programmatically configure CLI
- Build settings migration tools

**Next Step**: Decode gzipped response to document structure

---

### 3. Grove Config API (Tier 2 - HIGH)
```
GET https://api.anthropic.com/api/claude_code_grove
```
**Status**: ✅ 200 OK (Line 1)
**Response Time**: ~760ms
**Auth**: OAuth Bearer token
**Headers**:
- `Authorization: Bearer sk-...rAAA`
- `anthropic-beta: oauth-2025-04-20`
- `User-Agent: claude-cli/2.0.25 (external, cli)`

**Response**: Gzipped JSON (privacy/data sharing config)

**Customization Value**: ⭐⭐⭐
- Automate privacy settings
- Enforce compliance policies
- Manage data sharing across org
- Build privacy audit tools

**Next Step**: Decode gzipped response to document structure

---

### 4. Client Data API (Tier 2 - MEDIUM)
```
GET https://api.anthropic.com/api/oauth/claude_cli/client_data
```
**Status**: ✅ 200 OK (Line 2)
**Response Time**: ~1250ms
**Auth**: OAuth Bearer token
**Headers**:
- `Authorization: Bearer sk-...rAAA`
- `Content-Type: application/json`
- `User-Agent: axios/1.8.4`

**Response**:
```json
{
  "client_data": {}
}
```

**Customization Value**: ⭐⭐
- CLI-specific configuration storage
- Empty in current test (potential for custom data)
- May support custom client settings

**Note**: Returns empty object - may be for future use or requires setup

---

### 5. API Hello (Health Check)
```
GET https://api.anthropic.com/api/hello
```
**Status**: ✅ 200 OK (Lines 9, 11)
**Response Time**: ~730ms, ~720ms
**Auth**: None
**Headers**:
- `Cache-Control: no-cache`
- `User-Agent: axios/1.8.4`

**Response**:
```json
{
  "message": "hello"
}
```

**Customization Value**: ⭐
- Simple connectivity test
- API availability monitoring
- Uptime checks

---

### 6. Messages API (Tier 1 - EXCELLENT)
```
POST https://api.anthropic.com/v1/messages?beta=true
```
**Status**: ✅ 200 OK (Lines 3, 4, 6, 7)
**Response Time**: ~1200ms, ~1140ms, ~1130ms, ~1180ms
**Auth**: OAuth Bearer token
**Headers**:
- `Authorization: Bearer sk-...rAAA`
- `anthropic-beta: oauth-2025-04-20,interleaved-thinking-2025-05-14,fine-grained-tool-streaming-2025-05-14`
- `anthropic-version: 2023-06-01`
- `User-Agent: claude-cli/2.0.25 (external, cli)`
- `x-app: cli`

**Request Body** (example):
```json
{
  "model": "claude-haiku-4-5-20251001",
  "max_tokens": 1,
  "messages": [{"role": "user", "content": "quota"}],
  "metadata": {
    "user_id": "user_...session_..."
  }
}
```

**Response**: Streaming or JSON with message content, usage stats

**Response Headers** (Rate Limits):
- `anthropic-ratelimit-unified-5h-reset: 1761130800`
- `anthropic-ratelimit-unified-5h-status: allowed`
- `anthropic-ratelimit-unified-7d-reset: 1761181200`
- `anthropic-ratelimit-unified-7d-status: allowed_warning`
- `anthropic-ratelimit-unified-fallback-percentage: 0.5`

**Customization Value**: ⭐⭐⭐⭐⭐
- Core AI interaction
- Build custom CLI tools
- Implement automation workflows
- Create specialized interfaces
- Rate limit headers provide real-time quota info

---

### 7. Token Counting API (Tier 1 - HIGH)
```
POST https://api.anthropic.com/v1/messages/count_tokens?beta=true
```
**Status**: ✅ 200 OK (Line 8)
**Response Time**: ~660ms
**Auth**: OAuth Bearer token
**Headers**:
- `Authorization: Bearer sk-...rAAA`
- `anthropic-beta: claude-code-20250219,oauth-2025-04-20,interleaved-thinking-2025-05-14,fine-grained-tool-streaming-2025-05-14,token-counting-2024-11-01`
- `anthropic-version: 2023-06-01`
- `User-Agent: claude-cli/2.0.25 (external, cli)`

**Request Body**:
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "messages": [{"role": "user", "content": "foo"}],
  "tools": [...]
}
```

**Response**:
```json
{
  "input_tokens": 12915
}
```

**Customization Value**: ⭐⭐⭐⭐
- Cost estimation before API calls
- Token budget management
- Optimize prompt engineering
- Build cost tracking tools
- Prevent expensive requests

---

## 🔬 Usage Patterns Discovered

### CLI Startup Sequence
From the logs, the CLI makes these calls on startup (in parallel):

1. **Concurrent Health & Config Checks** (~1761113604-1761113605s):
   - `/api/claude_code_grove` (privacy config)
   - `/api/oauth/claude_cli/client_data` (client config)
   - `/v1/messages` (warmup requests)

2. **User Settings & Usage** (~1761113605-1761113608s):
   - `/api/oauth/account/settings` (user preferences)
   - `/api/hello` (connectivity)
   - `/api/oauth/usage` (quota check)
   - `/v1/messages/count_tokens` (token estimation)

**Total Startup Time**: ~4 seconds with parallel requests

### Headers Analysis

**Common OAuth Headers**:
```
Accept: application/json, text/plain, */*
Authorization: Bearer sk-ant-oat01-...
anthropic-beta: oauth-2025-04-20
Content-Type: application/json
User-Agent: claude-code/2.0.25 (or axios/1.8.4)
Accept-Encoding: gzip, compress, deflate, br
```

**Messages API Additional Headers**:
```
anthropic-version: 2023-06-01
anthropic-beta: oauth-2025-04-20,interleaved-thinking-2025-05-14,fine-grained-tool-streaming-2025-05-14
x-app: cli
x-stainless-runtime: node
x-stainless-runtime-version: v22.13.0
```

### Response Encoding
- Most OAuth endpoints return **gzipped JSON**
- Messages API returns **gzipped JSON** or **text/event-stream** (streaming)
- Client data returns **plain JSON**
- Hello endpoint returns **plain JSON**

---

## 📊 Rate Limit Information

From Messages API response headers, we discovered rate limit tracking:

### Rate Limit Windows
1. **5-hour window**: `anthropic-ratelimit-unified-5h-*`
   - Status: `allowed`, `allowed_warning`, `rate_limited`
   - Reset timestamp in headers

2. **7-day window**: `anthropic-ratelimit-unified-7d-*`
   - Status: `allowed`, `allowed_warning`, `rate_limited`
   - Reset timestamp in headers

### Rate Limit Headers
```
anthropic-ratelimit-unified-5h-reset: 1761130800
anthropic-ratelimit-unified-5h-status: allowed
anthropic-ratelimit-unified-7d-reset: 1761181200
anthropic-ratelimit-unified-7d-status: allowed_warning
anthropic-ratelimit-unified-fallback-percentage: 0.5
anthropic-ratelimit-unified-representative-claim: seven_day
```

**Usage**: These headers provide real-time rate limit status on every request, complementing the `/api/oauth/usage` endpoint data.

---

## 🚀 High-Value Customization Opportunities

### Immediate Implementation (Tier 1)

1. **Quota Monitoring Dashboard**
   - Poll `/api/oauth/usage` every 5 minutes
   - Display utilization bars (5h / 7d)
   - Alert when > 80% utilized
   - Show time until reset

2. **Cost Estimation Tool**
   - Use `/v1/messages/count_tokens` before requests
   - Calculate estimated cost per model
   - Provide budget warnings
   - Track cumulative costs

3. **Settings Sync Tool**
   - Export settings via `/api/oauth/account/settings`
   - Import settings to new machines
   - Version control user preferences
   - Team settings templates

### Advanced Implementation (Tier 2)

4. **Privacy Management**
   - Read `/api/claude_code_grove` config
   - Enforce org-wide policies
   - Audit data sharing settings
   - Automated compliance checks

5. **Rate Limit Intelligence**
   - Parse headers from every response
   - Predict when rate limits will hit
   - Queue requests when near limit
   - Implement exponential backoff

6. **Client Config Storage**
   - Use `/api/oauth/claude_cli/client_data`
   - Store custom CLI preferences
   - Sync across installations
   - Per-project configurations

---

## 🔧 Testing Scripts

### 1. test-usage-api.sh (Working ✅)
```bash
./test-usage-api.sh
```
- Auto-extracts token from ~/.claude/.credentials.json
- Falls back to CLAUDE_OAUTH_TOKEN env var
- Checks token expiry
- Returns quota utilization data

### 2. test-account-settings.sh (TODO)
```bash
#!/bin/bash
# Test account settings endpoint
TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json)

curl -s "https://api.anthropic.com/api/oauth/account/settings" \
  --header "Accept: application/json, text/plain, */*" \
  --header "Authorization: Bearer $TOKEN" \
  --header "anthropic-beta: oauth-2025-04-20" \
  --header "User-Agent: claude-code/2.0.25" \
  --compressed | jq .
```

### 3. test-grove-config.sh (TODO)
```bash
#!/bin/bash
# Test Grove privacy config endpoint
TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json)

curl -s "https://api.anthropic.com/api/claude_code_grove" \
  --header "Accept: application/json, text/plain, */*" \
  --header "Authorization: Bearer $TOKEN" \
  --header "anthropic-beta: oauth-2025-04-20" \
  --header "User-Agent: claude-cli/2.0.25 (external, cli)" \
  --compressed | jq .
```

### 4. test-count-tokens.sh (TODO)
```bash
#!/bin/bash
# Test token counting endpoint
TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json)

curl -s "https://api.anthropic.com/v1/messages/count_tokens?beta=true" \
  --header "Authorization: Bearer $TOKEN" \
  --header "anthropic-beta: token-counting-2024-11-01,oauth-2025-04-20" \
  --header "anthropic-version: 2023-06-01" \
  --header "Content-Type: application/json" \
  --data '{
    "model": "claude-sonnet-4-5-20250929",
    "messages": [{"role": "user", "content": "Hello world"}]
  }' | jq .
```

---

## 📝 Next Steps

### Phase 1: Decode Responses (Immediate)
- [ ] Decode account settings gzipped response
- [ ] Decode Grove config gzipped response
- [ ] Document response structures
- [ ] Update ALL-API-ENDPOINTS.md with findings

### Phase 2: Build Test Scripts (This Week)
- [x] test-usage-api.sh - ✅ DONE
- [ ] test-account-settings.sh
- [ ] test-grove-config.sh
- [ ] test-count-tokens.sh
- [ ] test-client-data.sh

### Phase 3: Custom Tools (Next Week)
- [ ] Quota monitoring daemon
- [ ] Cost estimation CLI tool
- [ ] Settings backup/restore script
- [ ] Privacy audit script

### Phase 4: Advanced Features (Later)
- [ ] Rate limit prediction engine
- [ ] Request queue manager
- [ ] Multi-account settings sync
- [ ] Usage analytics dashboard

---

## 🎯 Key Findings Summary

1. **8 Endpoints Confirmed Working** - All tested during normal CLI operation
2. **Parallel Request Pattern** - CLI makes concurrent API calls on startup
3. **Gzip Compression Standard** - Most responses are gzipped
4. **Rich Rate Limit Data** - Both dedicated endpoint + response headers
5. **Token Counting Available** - Pre-request cost estimation possible
6. **Settings Are Synced** - Account settings fetched on every startup
7. **Privacy Config Active** - Grove endpoint checked on startup
8. **Health Checks Regular** - Hello endpoint called periodically

**Conclusion**: The OAuth APIs provide extensive customization potential. With proper token management, we can build sophisticated automation tools for quota monitoring, cost optimization, settings management, and more.

---

**Files**:
- `log-2025-10-22-06-13-23.jsonl` - Source runtime logs
- `test-usage-api.sh` - Working test script
- `ALL-API-ENDPOINTS.md` - Complete endpoint catalog
- `USAGE-API-README.md` - Quick usage reference
- `claude-code-usage-api-report.org` - Detailed usage docs
