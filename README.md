# postiz-tiktok-patch

Imagen Docker derivada de Postiz oficial **v2.26.0** que quita el scope `video.list` del proveedor de TikTok de consumidor (`tiktok`). Sirve para una instalación autoalojada en Coolify.

No contiene secretos.

## Por qué existe

Las apps nuevas de TikTok ya no pueden obtener el scope `video.list` (la Display API dejó de ofrecerse). Postiz v2.26.0 todavía lo pide en el authorize URL, y TikTok responde `invalid_scope`. Es el issue [gitroomhq/postiz-app#2383](https://github.com/gitroomhq/postiz-app/issues/2383).

Este parche solo toca los JS compilados:

- `/app/apps/backend/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js`
- `/app/apps/orchestrator/dist/libraries/nestjs-libraries/src/integrations/social/tiktok.provider.js`

No modifica `tiktok-business`, la base de datos, ni JWT/ENCRYPTION_KEY. Las llamadas de analítica a `/v2/video/list/` siguen en el código, pero ya estaban en try/catch y simplemente no devolverán esos datos.

Si el `RUN` no puede quitar `video.list` de ambos archivos, el build falla.

## Cómo se usa en Coolify

1. Coolify construye esta imagen en el VPS (aplicación Dockerfile, sin dominio público).
2. El servicio Compose de Postiz apunta a la etiqueta local de esa imagen (`pull_policy: never`), no a `ghcr.io/gitroomhq/postiz-app:v2.26.0`.
3. No uses `entrypoint` ni `command` en el compose de Postiz para aplicar el parche: en Coolify 4.0.0-beta.468 eso provocó un restart loop de todo el stack.

## Cómo actualizar Postiz

1. En el `Dockerfile`, cambia `FROM ghcr.io/gitroomhq/postiz-app:v2.26.0` por el tag nuevo.
2. Confirma que el issue #2383 sigue abierto. Si el release ya no pide `video.list`, no hace falta este repo: vuelve a la imagen oficial (ver revertir).
3. Haz commit y push a `main`, reconstruye la app en Coolify y vuelve a desplegar el servicio Postiz.

## Cómo revertir

En el compose del servicio Postiz, restaura:

```yaml
image: ghcr.io/gitroomhq/postiz-app:v2.26.0
```

(o el tag oficial que corresponda) y quita `pull_policy: never`. Lanza un deploy completo. No hace falta borrar este repositorio.