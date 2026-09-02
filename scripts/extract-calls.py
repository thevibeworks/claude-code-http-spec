#!/usr/bin/env python3
"""extract-calls.py - printable byte windows around endpoint anchors.

The old `rg -B 10 -A 20 '<anchor>' cli.js` recipe assumed a prettified bundle
with line breaks. Releases now ship a compiled binary: the JavaScript is still
there in full, but as one enormous line, so `rg` context flags return either
nothing useful or the whole module. Cutting a fixed *byte* window around each
anchor gives the same reviewable context back.

Each output file records the anchor and the offsets, so any claim in the spec
can be re-opened at the exact position that supports it.

Usage:
  extract-calls.py <binary> <out-dir> [--anchors anchors.tsv]
                   [--before N] [--after N] [--max K]

anchors.tsv is `name<TAB>anchor` per line. With no --anchors, the built-in set
below is used; it tracks the families the specs document.
"""
import argparse
import os
import sys

ANCHORS = [
    ("api-cli-bootstrap", "/api/claude_cli/bootstrap"),
    ("api-cowork-remote-devices", "/cowork/remote_devices"),
    ("api-directory-servers", "/api/directory/servers"),
    ("api-event-logging", "/api/event_logging/"),
    ("api-frame-comments", "/api/frame/comments/"),
    ("api-frame-contract", "/api/frame/contract/"),
    ("api-frame-deploy", "/api/frame/deploy/"),
    ("api-frame-upload", "/api/frame/upload"),
    ("api-grove-settings", "/api/claude_code_grove"),
    ("api-hello", "/api/hello"),
    ("api-mcp-connectors", "/mcp/connectors/"),
    ("api-oauth-account-settings", "/api/oauth/account/settings"),
    ("api-oauth-cri", "/api/oauth/cri"),
    ("api-oauth-profile", "/api/oauth/profile"),
    ("api-oauth-usage", "/api/oauth/usage"),
    ("api-oauth-validate", "/api/oauth/validate"),
    ("api-penguin-mode", "/api/claude_code_penguin_mode"),
    ("api-plugin-ratings", "/plugin_ratings"),
    ("api-plugins-search", "/plugins/search"),
    ("api-projects", "/claude_code/pro_trial"),
    ("api-skills-search", "/skills/search"),
    ("auth-header-builder", "function Sj("),
    ("auth-modes", 'n.auth==="teleport-org"'),
    ("mcp-registry", "/mcp-registry/v0/servers"),
    ("v1-code-agent-proxy", "/v1/code/agent-proxy/"),
    ("v1-code-memory", "/v1/code/local/memory/"),
    ("v1-code-scm-connectors", "/v1/code/scm-connectors"),
    ("v1-code-self-hosted-runners", "/v1/code/runners/self-hosted/"),
    ("v1-code-triggers", "/v1/code/triggers"),
    ("v1-code-webhook-triggers", "/v1/code/webhook-triggers"),
    ("v1-deployments", "/v1/deployments"),
    ("v1-design", "/v1/design/"),
    ("v1-dreams", "/v1/dreams"),
    ("v1-environments", "/v1/environments"),
    ("v1-mcp-servers", "/v1/mcp_servers"),
    ("v1-memory-stores", "/v1/memory_stores"),
    ("v1-messages", '"/v1/messages"'),
    ("v1-tunnels", "/v1/tunnels"),
    ("v1-ultrareview", "/v1/ultrareview/"),
    ("v1-user-profiles", "/v1/user_profiles"),
    ("v1-vaults", "/v1/vaults"),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("binary")
    ap.add_argument("out_dir")
    ap.add_argument("--anchors")
    ap.add_argument("--before", type=int, default=500)
    ap.add_argument("--after", type=int, default=900)
    ap.add_argument("--max", type=int, default=12, dest="limit")
    args = ap.parse_args()

    anchors = ANCHORS
    if args.anchors:
        anchors = []
        for line in open(args.anchors):
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            name, _, anchor = line.partition("\t")
            anchors.append((name, anchor))

    data = open(args.binary, "rb").read()
    os.makedirs(args.out_dir, exist_ok=True)

    for name, anchor in sorted(anchors):
        needle = anchor.encode()
        hits, idx = [], 0
        while len(hits) < args.limit:
            idx = data.find(needle, idx)
            if idx == -1:
                break
            s = max(0, idx - args.before)
            e = min(len(data), idx + len(needle) + args.after)
            window = "".join(chr(b) if 32 <= b < 127 else "." for b in data[s:e])
            hits.append(f"--- offset {idx} ---\n{window}\n")
            idx += len(needle)
        with open(os.path.join(args.out_dir, name + ".txt"), "w") as f:
            f.write(f"# anchor: {anchor}\n# occurrences shown: {len(hits)}\n\n")
            f.write("\n".join(hits))
        print(f"{name}: {len(hits)}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
