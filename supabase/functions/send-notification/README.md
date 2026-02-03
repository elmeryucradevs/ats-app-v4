# Send Notification Edge Function

Supabase Edge Function para enviar notificaciones push a través de Firebase Cloud Messaging (FCM).

## Setup

1. **Configurar FCM Server Key en Supabase Secrets:**
   ```bash
   # En Supabase Dashboard:
   # Settings → Secrets → Add new secret
   # Name: FCM_SERVER_KEY
   # Value: [tu server key de Firebase]
   ```

2. **Desplegar la función:**
   ```bash
   supabase functions deploy send-notification
   ```

## Uso

```bash
curl -X POST \
  'https://[your-project-ref].supabase.co/functions/v1/send-notification' \
  -H 'Authorization: Bearer [your-anon-key]' \
  -H 'Content-Type': 'application/json' \
  -d '{
    "title": "Título de la notificación",
    "body": "Cuerpo del mensaje",
    "type": "general"
  }'
```

## Parámetros

- `title` (requerido): Título de la notificación
- `body` (requerido): Cuerpo del mensaje
- `type` (opcional): `program`, `news`, o `general` (default: `general`)
- `data` (opcional): Objeto JSON con datos adicionales
- `tokens` (opcional): Array de tokens específicos
- `platform` (opcional): Filtrar por plataforma (`web`, `android`, `ios`, `windows`, `macos`)

## Ver documentación completa

Ver `docs/fcm-integration-guide.md` para ejemplos completos y casos de uso.
