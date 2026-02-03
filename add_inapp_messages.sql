-- ==============================================================================
-- SETUP IN-APP MESSAGING TABLE + ANALYTICS FUNCTIONS
-- ==============================================================================
-- Crea la tabla para mensajes in-app y las funciones RPC para analytics.
-- Habilita REALTIME para que los mensajes se muestren al instante.
-- 
-- EJECUTAR EN: Supabase Dashboard > SQL Editor
-- ==============================================================================

-- 1. Crear tabla de mensajes in-app
CREATE TABLE IF NOT EXISTS inapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  button_text TEXT DEFAULT 'Aceptar',
  action_url TEXT,
  layout TEXT DEFAULT 'card', -- card, fullscreen, banner, modal
  is_active BOOLEAN DEFAULT TRUE,
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  views_count INTEGER DEFAULT 0,
  clicks_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Crear índice para búsqueda rápida de mensajes activos
CREATE INDEX IF NOT EXISTS idx_inapp_active_start 
ON inapp_messages (is_active, start_date DESC);

-- 3. Función RPC para incrementar vistas
CREATE OR REPLACE FUNCTION increment_inapp_views(message_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE inapp_messages
  SET views_count = views_count + 1
  WHERE id = message_id;
END;
$$;

-- 4. Función RPC para incrementar clicks
CREATE OR REPLACE FUNCTION increment_inapp_clicks(message_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE inapp_messages
  SET clicks_count = clicks_count + 1
  WHERE id = message_id;
END;
$$;

-- 5. Habilitar Realtime (Si no está habilitado globalmente)
-- ALTER PUBLICATION supabase_realtime ADD TABLE inapp_messages;

-- 6. Row Level Security (RLS) - Permitir lectura pública
ALTER TABLE inapp_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access" ON inapp_messages
  FOR SELECT
  USING (true);

CREATE POLICY "Allow service role full access" ON inapp_messages
  FOR ALL
  USING (auth.role() = 'service_role');

-- 7. Insertar mensaje de prueba (OPCIONAL)
-- INSERT INTO inapp_messages (title, body, button_text, layout)
-- VALUES (
--   '¡Bienvenido!',
--   'Gracias por usar nuestra aplicación. Mantente conectado para las últimas noticias.',
--   'Entendido',
--   'card'
-- );

COMMENT ON TABLE inapp_messages IS 'Mensajes in-app para mostrar en la aplicación móvil';
