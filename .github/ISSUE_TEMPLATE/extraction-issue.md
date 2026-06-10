---
name: Extraction issue
about: A documented literal looks wrong, missing, or stale
title: "[extraction] "
labels: extraction
---

**Release version**
The version this concerns (e.g. `2.1.170`).

**What looks wrong**
The literal, endpoint, beta flag, or env var that is wrong/missing, and the
file path under `extractions/` or `specs/` where it lives.

**Reproduction pattern**
The `rg` or `strings` pattern that does or does not reproduce it, e.g.:

```
strings binary_2.1.170/claude | rg '/api/oauth/profile'
```

**Expected vs actual**
What you expected to see vs what is documented.
