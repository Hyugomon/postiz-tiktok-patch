# Patched Postiz image for self-hosting.
# Workaround for https://github.com/gitroomhq/postiz-app/issues/2383
# New TikTok developer apps cannot be granted the video.list scope
# (Display API is no longer offered). Official Postiz v2.26.0 still
# requests it in the consumer "tiktok" provider, so authorization
# fails with invalid_scope. This image removes video.list only from
# that provider. It does not change tiktok-business, the database,
# or any secrets.
#
# Revert: point Coolify back to ghcr.io/gitroomhq/postiz-app:<tag>
# Update: bump the FROM tag, keep the RUN patch, rebuild, redeploy.

FROM ghcr.io/gitroomhq/postiz-app:v2.26.0

USER root
RUN set -eu; \
    python3 - <<'PY'
from pathlib import Path
import re, sys

files = [
    Path("/app/apps/backend/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js"),
    Path("/app/apps/orchestrator/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js"),
]
for path in files:
    if not path.is_file():
        raise SystemExit(f"missing {path}")
    text = path.read_text()
    start = text.find("this.scopes = [")
    if start < 0:
        raise SystemExit(f"no scopes array in {path}")
    end = text.find("];", start) + 2
    block = text[start:end]
    if "'video.list'" not in block:
        raise SystemExit(f"unexpected scopes (video.list already absent) in {path}: {block}")
    new_block = re.sub(r"(\s*)'video\.list',\s*", r"\1", block, count=1)
    if "'video.list'" in new_block:
        raise SystemExit(f"failed to remove video.list from {path}")
    path.write_text(text[:start] + new_block + text[end:])
    print(f"patched {path}")
    print(new_block)
PY
# Fail the build if video.list (scope, not the /video/list API path) remains.
RUN set -eu; \
    for f in \
      /app/apps/backend/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js \
      /app/apps/orchestrator/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js; do \
      if grep -F "video.list" "$f"; then \
        echo "ERROR: $f still contains video.list" >&2; \
        exit 1; \
      fi; \
    done; \
    echo "tiktok video.list scope removed from both provider files"