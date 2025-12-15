# Package Changes: v2.0.58 → v2.0.69

## New Files

### `bun.lock` (551 bytes)
Bun package manager lockfile. Contains optional dependencies for `sharp` image library:
```json
{
  "optionalDependencies": {
    "@img/sharp-darwin-arm64": "^0.33.5",
    "@img/sharp-darwin-x64": "^0.33.5",
    "@img/sharp-linux-arm": "^0.33.5",
    "@img/sharp-linux-arm64": "^0.33.5",
    "@img/sharp-linux-x64": "^0.33.5",
    "@img/sharp-linuxmusl-arm64": "^0.33.5",
    "@img/sharp-linuxmusl-x64": "^0.33.5",
    "@img/sharp-win32-x64": "^0.33.5"
  }
}
```

**Implications:**
- Build tooling uses Bun (alternative JS runtime/bundler)
- CLI supports `sharp` for native image processing on all platforms
- Optional deps = falls back gracefully if native binaries unavailable

### `resvg.wasm` (2.4MB)
SVG rendering library (resvg) compiled to WebAssembly.

**Purpose:** Render SVG to pixels without native dependencies.

**Features extracted from cli.js:**
```
resvg_new()      - Create renderer from SVG string
resvg_width()    - Get rendered width
resvg_height()   - Get rendered height
resvg_render()   - Render to pixel buffer
resvg_toString() - Convert back to SVG string
resvg_innerBBox() - Get inner bounding box
resvg_getBBox()   - Get full bounding box
resvg_cropByBBox() - Crop to bounding box
resvg_imagesToResolve() - External image resolution
resvg_resolveImage()    - Resolve external images
```

**Loading strategy (from cli.js):**
1. Check for Bun runtime with embedded files (`Bun.embeddedFiles`)
2. Fall back to file system path relative to module
3. Error if WASM not found

**Use cases:**
- Canvas-based image generation (skills like `canvas-design`)
- PDF generation with embedded SVGs
- Algorithmic art rendering (`algorithmic-art` skill)
- GIF creation (`slack-gif-creator` skill)
- Visual artifact generation

### `tree-sitter.wasm` + `tree-sitter-bash.wasm`
Both existed in v2.0.58, unchanged sizes. Used for:
- Syntax-aware bash command parsing
- Environment variable extraction from inline definitions
- Semantic code highlighting

## Removed Files

### `vendor/claude-code-jetbrains-plugin/` (entire directory!)
**40+ JAR files removed** including:
```
claude-code-jetbrains-plugin-0.1.12-beta.jar
kotlin-stdlib-2.1.20.jar
ktor-client-*-3.0.2.jar
kotlinx-coroutines-*-1.9.0.jar
...and 36 more dependency JARs
```

**Size impact:** ~15MB removed from npm package

**Implications:**
- JetBrains plugin now distributed separately (not bundled in npm)
- Docs URL changed: `code.claude.com/docs/en/jetbrains` → `docs.claude.com/s/claude-code-jetbrains`
- Reduces npm package bloat for users who don't use JetBrains IDEs

## Summary

| Change | Impact |
|--------|--------|
| +`bun.lock` | Build tooling now uses Bun |
| +`resvg.wasm` | Native-free SVG→PNG rendering |
| -`vendor/jetbrains/` | Plugin unbundled, ~15MB smaller |

## Verification

```bash
# Compare package sizes
ls -lh anthropic-ai-claude-code-2.0.58.tgz  # 35MB
ls -lh anthropic-ai-claude-code-2.0.69.tgz  # 25MB (10MB smaller!)

# Verify resvg is used
rg 'resvg' package/cli.js | wc -l  # ~20 references
```

## Package Size Analysis

```
v2.0.58: 35MB (tgz)
v2.0.69: 25MB (tgz)
Reduction: 10MB (29% smaller)
```

Despite adding resvg.wasm (2.4MB), removing the JetBrains plugin (~15MB)
resulted in a net reduction of 10MB.
