# Guía de Integración FCM v1 API con Supabase

## 🚀 Configuración Inicial

### 1. Obtener Service Account de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **ATESUR**
3. Click en ⚙️ → **Project settings**
4. Ve a la pestaña **Service accounts**
5. Click en **Generate new private key**
6. Descarga el archivo JSON (ya lo tienes: `atesur-app-v4-firebase-adminsdk-fbsvc-adc7215fc9.json`)

### 2 Configurar en Supabase

Necesitas configurar 3 secrets en Supabase:

1. Ve a [Supabase Dashboard](https://app.supabase.com/)
2. Selecciona tu proyecto
3. Ve a **Settings** → **Secrets**
4. Agrega los siguientes secrets (extráelos del JSON que descargaste):

```
FIREBASE_PROJECT_ID = atesur-app-v4
FIREBASE_CLIENT_EMAIL = firebase-adminsdk-fbsvc@atesur-app-v4.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY = -----BEGIN PRIVATE KEY-----\nMIIEvwIB...(tu clave completa)...==\n-----END PRIVATE KEY-----\n
```

> **Importante**: En `FIREBASE_PRIVATE_KEY`, mantén los `\n` tal como aparecen en el JSON.

### 3. Desplegar Edge Function

> ✅ **Ya desplegada!** La función está disponible en:
> `https://kholyiqxboourdwavkci.supabase.co/functions/v1/send-notification`

```powershell
# Para volver a desplegar (si haces cambios):
npx supabase login
npx supabase link
npx supabase functions deploy send-notification
```

---

## 📨 Cómo Enviar Notificaciones

La API es la misma, pero ahora usa FCM v1 (OAuth 2.0) internamente.

### Usando PowerShell Script (Recomendado)

```powershell
# 1. Edita test_notification.ps1 y agrega tu SUPABASE_ANON_KEY
# 2. Ejecuta:
.\test_notification.ps1 -Title "¡Nueva transmisión!" -Body "En vivo ahora" -Type "program"
```

### Con cURL

```bash
curl -X POST \
  'https://kholyiqxboourdwavkci.supabase.co/functions/v1/send-notification' \
  -H 'Authorization: Bearer TU_ANON_KEY_AQUI' \
  -H 'apikey: TU_ANON_KEY_AQUI' \
  -H 'Content-Type: application/json' \
  -d '{
    "title": "¡Nueva transmisión!",
    "body": "En vivo ahora",
    "type": "program"
  }'
```

### Desde JavaScript

```javascript
const response = await fetch(
  'https://kholyiqxboourdwavkci.supabase.co/functions/v1/send-notification',
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      title: '🔴 EN VIVO: Noticiero',
      body: 'Tu programa favorito acaba de comenzar',
      type: 'program',
      data: {
        screen: 'player',
        programId: '123'
      }
    })
  }
)

const result = await response.json()
console.log(`Enviado a ${result.sentTo} de ${result.total} dispositivos`)
```

---

## 🎯 Casos de Uso

### 1. Notificación de Programa en Vivo

```json
{
  "title": "🔴 EN VIVO: Noticiero ATESUR",
  "body": "Tu programa favorito acaba de comenzar",
  "type": "program",
  "data": {
    "screen": "player",
    "programId": "abc123"
  }
}
```

### 2. Noticia Importante

```json
{
  "title": "📰 ÚLTIMA HORA",
  "body": "Importante actualización sobre...",
  "type": "news",
  "data": {
    "screen": "news",
    "newsId": "456"
  }
}
```

### 3. Solo a una Plataforma

```json
{
  "title": "Actualización disponible",
  "body": "Nueva versión de la app",
  "platform": "android"
}
```

---

## 🔧 Automatización con Triggers

### Trigger Automático para Noticias

```sql
CREATE OR REPLACE FUNCTION notify_breaking_news()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_breaking = true THEN
    PERFORM
      net.http_post(
        url := 'https://[your-project-ref].supabase.co/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Authorization', 'Bearer [service-role-key]',
          'Content-Type', 'application/json'
        ),
        body := jsonb_build_object(
          'title', '📰 ÚLTIMA HORA',
          'body', NEW.title,
          'type', 'news',
          'data', jsonb_build_object('newsId', NEW.id::text)
        )
      );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_breaking_news
AFTER INSERT ON news
FOR EACH ROW
EXECUTE FUNCTION notify_breaking_news();
```

---

## 📊 Monitoreo

### Ver notificaciones enviadas

```sql
SELECT title, body, type, sent_at
FROM notifications
ORDER BY sent_at DESC
LIMIT 10;
```

### Ver tokens activos por plataforma

```sql
SELECT platform, COUNT(*) as devices
FROM fcm_tokens
WHERE last_used_at > NOW() - INTERVAL '30 days'
GROUP BY platform;
```

---

## 🐛 Troubleshooting

### "Firebase credentials no configuradas"
- Verifica los 3 secrets en Supabase (PROJECT_ID, CLIENT_EMAIL, PRIVATE_KEY)
- Redeploya después de agregar los secrets

### "Invalid JWT"
- Asegúrate de que `FIREBASE_PRIVATE_KEY` tenga los `\n` correctos
- Copia la private key EXACTAMENTE como aparece en el JSON

### Ver logs

```powershell
npx supabase functions logs send-notification

# O en el Dashboard:
# https://supabase.com/dashboard/project/kholyiqxboourdwavkci/functions
```

---

## ⚙️ Diferencias con Legacy Server Key

| Legacy API | FCM v1 API |
|------------|------------|
| Un solo Server Key | Service Account JSON (3 valores) |
| `https://fcm.googleapis.com/fcm/send` | `https://fcm.googleapis.com/v1/projects/{project}/messages:send` |
| Header: `Authorization: key=SERVER_KEY` | Header: `Authorization: Bearer {OAuth_token}` |
| Batch notifications (1000 tokens) | Individual notifications |
| ❌ Deprecated | ✅ Actual y soportado |

---

## 💡 Mejores Prácticas

1. **Nunca expongas** las credenciales del Service Account
2. **Usa Supabase Secrets** para guardar las credenciales
3. **Monitorea** los resultados (`sentTo` vs `failed`)
4. **Prueba primero** con `tokens` específicos antes de broadcast
5. **Limita** la frecuencia de notificaciones broadcast

---

## � Seguridad

- ✅ Las credenciales están en Supabase Secrets (no en código)
- ✅ La Edge Function usa Service Role Key (solo backend)
- ✅ OAuth tokens se generan dinámicamente (expiran en 1 hora)
- ✅ RLS está habilitado en las tablas

Tu implementación está usando **FCM v1 API**, la versión moderna y segura de Firebase Cloud Messaging.
