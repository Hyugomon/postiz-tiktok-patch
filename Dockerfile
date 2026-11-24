# syntax=docker/dockerfile:1
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
COPY patch.py /tmp/postiz-tiktok-patch.py
RUN python3 /tmp/postiz-tiktok-patch.py \
 && rm /tmp/postiz-tiktok-patch.py \
 && ! grep -F 'video.list' /app/apps/backend/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js \
 && ! grep -F 'video.list' /app/apps/orchestrator/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js \
 && echo 'tiktok video.list scope removed from both provider files'