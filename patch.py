from pathlib import Path
import re
import sys

FILES = [
    Path("/app/apps/backend/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js"),
    Path("/app/apps/orchestrator/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js"),
]

for path in FILES:
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