-- ==============================================================================
-- TABLA INAPP_MESSAGES PARA MENSAJES IN-APP DIRECTOS
-- ==============================================================================
-- Ejecutar en Supabase Dashboard > SQL Editor
-- ==============================================================================

-- 1. Crear la tabla
CREATE TABLE IF NOT EXISTS inapp_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  image_url text,
  button_text text DEFAULT 'Aceptar',
  action_url text,
  layout text DEFAULT 'card', -- card, modal, banner, image
  is_active boolean DEFAULT true,
  target_platform text, -- null = all, 'android', 'ios'
  start_date timestamptz DEFAULT now(),
  end_date timestamptz,
  views_count integer DEFAULT 0,
  clicks_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Índices para búsquedas eficientes
CREATE INDEX IF NOT EXISTS idx_inapp_active ON inapp_messages(is_active);
CREATE INDEX IF NOT EXISTS idx_inapp_dates ON inapp_messages(start_date, end_date);

-- 3. Trigger para updated_at
CREATE OR REPLACE FUNCTION update_inapp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_inapp_messages_updated_at ON inapp_messages;
CREATE TRIGGER update_inapp_messages_updated_at
    BEFORE UPDATE ON inapp_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_inapp_updated_at();

-- 4. Habilitar RLS
ALTER TABLE inapp_messages ENABLE ROW LEVEL SECURITY;

-- 5. Políticas - Lectura pública, escritura desde editor (anon)
CREATE POLICY "Allow public read on inapp_messages" 
ON inapp_messages FOR SELECT 
TO anon, authenticated
USING (true);

CREATE POLICY "Allow anon insert on inapp_messages" 
ON inapp_messages FOR INSERT 
TO anon 
WITH CHECK (true);

CREATE POLICY "Allow anon update on inapp_messages" 
ON inapp_messages FOR UPDATE 
TO anon 
USING (true);

CREATE POLICY "Allow anon delete on inapp_messages" 
ON inapp_messages FOR DELETE 
TO anon 
USING (true);

-- 6. Habilitar Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE inapp_messages;

-- 7. Comentarios
COMMENT ON TABLE inapp_messages IS 'Mensajes in-app enviados desde el editor de escritorio';
COMMENT ON COLUMN inapp_messages.layout IS 'Tipo de layout: card, modal, banner, image';
COMMENT ON COLUMN inapp_messages.is_active IS 'Si el mensaje está activo para mostrar';
