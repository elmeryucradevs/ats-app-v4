# Creación de Tabla Programs en Supabase

## 📋 Pasos para Crear la Tabla de Programación

### 1. Copiar el SQL

Abre el archivo `supabase_programs_schema.sql` y copia todo su contenido.

### 2. Ejecutar en Supabase

1. Ve a https://supabase.com/dashboard/project/kholyiqxboourdwavkci/sql
2. Click en **New Query**
3. Pega el contenido del archivo SQL
4. Click en **Run** (▶️)

### 3. Verificar Creación

1. Ve a **Table Editor**
2. Deberías ver la nueva tabla `programs`
3. Columnas:
   - `id` (UUID)
   - `title`, `description`, `category`
   - `day_of_week` (0=Domingo, 6=Sábado)
   - `start_time`, `end_time`
   - `host`, `image_url`
   - `is_live`, `is_active`

### 4. Agregar Datos de Ejemplo (Opcional)

Si quieres datos de prueba, descomenta la sección `DATOS DE EJEMPLO` al final del SQL antes de ejecutarlo.

### 5. Recargar la App

Una vez creada la tabla, recarga la app en Chrome (F5) y los errores desaparecerán.

---

## 📝 Estructura de la Tabla

```sql
programs (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  day_of_week INTEGER (0-6),  -- 0=Domingo
  start_time TIME,
  end_time TIME,
  host TEXT,
  image_url TEXT,
  is_live BOOLEAN,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

---

## ✅ Verificación

Después de crear la tabla, verifica en la app que:
- No aparezcan más errores de "Could not find table"
- La programación se muestre en la interfaz
- Puedas navegar sin problemas
