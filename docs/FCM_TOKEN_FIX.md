# FCM Token Registration - Análisis y Corrección

## 🔍 Problema Identificado

El código de Flutter para guardar tokens FCM tenía un error sutil pero importante:

### Código Original (Incorrecto)
```dart
await supabase.from('fcm_tokens').upsert({
  'token': token,
  'platform': platform,
  'last_used_at': DateTime.now().toIso8601String(),
});
```

### ❌ Qué estaba mal:
- **Faltaba el parámetro `onConflict`**
- Sin este parámetro, Supabase no sabe qué campo usar para detectar duplicados
- Podría fallar al intentar insertar el mismo token dos veces
- No actualizaba correctamente `last_used_at` cuando el token ya existía

## ✅ Solución Implementada

### Código Corregido
```dart
await supabase.from('fcm_tokens').upsert(
  {
    'token': token,
    'platform': platform,
    'last_used_at': DateTime.now().toIso8601String(),
  },
  onConflict: 'token', // ← CRÍTICO: especifica el campo único
);
```

### ✅ Qué hace ahora:
1. **Si el token NO existe:** Inserta un nuevo registro
2. **Si el token YA existe:** Actualiza `platform` y `last_used_at`
3. **Evita errores de duplicación:** El campo `token` es UNIQUE en la BD

## 📊 Flujo de Registro de Tokens

```
App inicia
    ↓
main.dart inicializa Firebase
    ↓
NotificationService.initialize()
    ↓
Solicita permisos FCM
    ↓
Obtiene token (web usa VAPID key)
    ↓
_saveTokenToDatabase(token)
    ↓
Detecta plataforma (web/android/ios/windows)
    ↓
upsert en tabla fcm_tokens
    ↓
✅ Token guardado en Supabase
```

## 🔧 Archivo Modificado

- **[notification_service.dart](file:///c:/Users/eyucr/Desktop/flutter/atesur_app_v4/lib/src/core/services/notification_service.dart#L175-L184)** (líneas 175-184)

## 🧪 Cómo Verificar

### 1. Ejecuta la app Flutter
```powershell
cd c:\Users\eyucr\Desktop\flutter\atesur_app_v4
flutter run
```

### 2. Busca estos logs
```
[Main] 🔔 Inicializando NotificationService...
[NotificationService] Inicializando FCM...
[NotificationService] Permisos: authorized
[NotificationService] Token FCM obtenido
[NotificationService] Token guardado en Supabase
[NotificationService] ✅ FCM inicializado correctamente
```

### 3. Verifica en Supabase
Ve a: https://supabase.com/dashboard/project/kholyiqxboourdwavkci/editor

Ejecuta:
```sql
SELECT token, platform, created_at, last_used_at 
FROM fcm_tokens 
ORDER BY created_at DESC;
```

Deberías ver al menos un token registrado.

### 4. Prueba notificaciones
```powershell
.\test_notification.ps1
```

Ahora debería mostrar:
```
[OK] Notificacion enviada exitosamente!
  Enviadas: 1
  Total: 1
  Fallidas: 0
```

## ⚠️ Notas Importantes

### VAPID Key para Web
Si usas la app en **web**, necesitas configurar el VAPID key en `EnvConfig`:

1. Ve a Firebase Console → Project Settings → Cloud Messaging
2. Copia el **Web Push certificate** (VAPID key)
3. Agrégalo en `.env` o dart-define:
   ```
   FIREBASE_VAPID_KEY=tu-vapid-key-aqui
   ```

Sin el VAPID key, la app web NO podrá obtener tokens FCM.

### Permisos en el Navegador
En web, asegúrate de:
1. Permitir notificaciones cuando el navegador lo solicite
2. Usar HTTPS o localhost (FCM no funciona en HTTP)

## 🎯 Resultado Esperado

Después de este fix:
- ✅ Los tokens FCM se guardan correctamente en Supabase
- ✅ Cada vez que la app inicie, actualiza `last_used_at`
- ✅ No hay errores de duplicación
- ✅ El script `test_notification.ps1` encuentra tokens y envía notificaciones
