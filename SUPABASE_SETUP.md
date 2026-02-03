# Guía de Configuración de Supabase para ATESUR App V4

## 📋 Pasos para Configurar Supabase

### Paso 1: Acceder a Supabase Dashboard

1. Ve a https://supabase.com/dashboard
2. Inicia sesión con tu cuenta
3. Selecciona tu proyecto o crea uno nuevo si no tienes

---

### Paso 2: Obtener Credenciales del Proyecto

1. En el Dashboard, ve a **Settings** → **API**
2. Copia los siguientes valores:
   - **Project URL** (ejemplo: `https://xxxxx.supabase.co`)
   - **anon/public key** (la clave larga que empieza con `eyJ...`)

---

### Paso 3: Actualizar Variables de Entorno

#### Opción A: Archivo .env (para Mobile/Desktop)

Crea o edita el archivo `.env` en la raíz del proyecto:

```env
# SUPABASE
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
```

#### Opción B: EnvConfig.dart (para Web)

Edita `lib/src/core/config/env_config.dart` y actualiza los `webFallback`:

```dart
static String get supabaseUrl => _getPlatformValue(
  'SUPABASE_URL',
  fallback: '',
  webFallback: 'https://tu-proyecto.supabase.co', // ← Actualizar aquí
);

static String get supabaseAnonKey => _getPlatformValue(
  'SUPABASE_ANON_KEY',
  fallback: '',
  webFallback: 'tu-anon-key-aqui', // ← Actualizar aquí
);
```

---

### Paso 4: Aplicar Schema SQL

1. En Supabase Dashboard, ve a **SQL Editor**
2. Click en **New Query**
3. Copia y pega el contenido del archivo `supabase_fcm_schema.sql`
4. Click en **Run** (▶️)

**Tablas que se crearán:**
- ✅ `fcm_tokens` - Tokens de dispositivos para notificaciones
- ✅ `notifications` - Registro de notificaciones enviadas
- ✅ Función `cleanup_old_fcm_tokens()` - Limpieza automática

---

### Paso 5: Verificar Tablas Creadas

1. Ve a **Table Editor** en el Dashboard
2. Deberías ver las tablas:
   - `fcm_tokens`
   - `notifications`

---

### Paso 6: Configurar Row Level Security (Opcional)

Las políticas RLS ya están incluidas en el schema SQL:

- **fcm_tokens**: Acceso público para insert/update
- **notifications**: Lectura pública, escritura solo para autenticados

Para deshabilitarlas temporalmente durante desarrollo:

```sql
ALTER TABLE fcm_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
```

---

### Paso 7: Probar Conexión

Ejecuta la app y verifica en los logs:

```
✅ [Supabase] Inicializado correctamente
✅ Variables de entorno cargadas correctamente
```

Si ves errores como:
```
❌ ClientException: Failed to fetch
```

Verifica que:
- Las URLs estén correctas
- La anon key sea la correcta
- El proyecto Supabase esté activo

---

## 🔧 Troubleshooting

### Error: "relation does not exist"
→ Las tablas no se crearon. Vuelve a ejecutar el SQL en el paso 4.

### Error: "Invalid API key"
→ La SUPABASE_ANON_KEY es incorrecta. Verifica en Settings → API.

### Error: "Failed to fetch"
→ La SUPABASE_URL es incorrecta o hay problemas de red.

### Error: "permission denied"
→ Las políticas RLS están bloqueando. Desactívalas temporalmente para desarrollo.

---

## ✅ Verificación Final

Después de configurar, deberías poder:

1. ✅ Ver las tablas en Supabase Table Editor
2. ✅ Ejecutar la app sin errores de Supabase
3. ✅ Los tokens FCM se guardarán automáticamente al iniciar
4. ✅ Las notificaciones se registrarán en la tabla

---

## 📝 Datos de Prueba (Opcional)

Para probar que todo funciona, puedes insertar un token de prueba:

```sql
INSERT INTO fcm_tokens (token, platform)
VALUES ('test_token_123', 'web');
```

Luego verifica en Table Editor que aparezca el registro.

---

## 🚀 Siguiente Paso

Una vez configurado Supabase, el siguiente paso es probar las notificaciones desde Firebase Console!
