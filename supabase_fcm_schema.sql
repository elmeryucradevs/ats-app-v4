-- ===================================
-- ATESUR APP V4 - PUSH NOTIFICATIONS
-- Supabase Database Schema
-- ===================================

-- Tabla para almacenar tokens FCM de dispositivos
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT UNIQUE NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('web', 'android', 'ios', 'windows', 'macos')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para búsquedas rápidas por token
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);

-- Índice para búsquedas por plataforma
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_platform ON fcm_tokens(platform);

-- Índice para limpieza de tokens antiguos
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_last_used ON fcm_tokens(last_used_at);

-- Tabla para registro de notificaciones enviadas
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('program', 'news', 'general')),
    data JSONB DEFAULT '{}'::jsonb,
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para búsquedas por tipo
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);

-- Índice para búsquedas por fecha
CREATE INDEX IF NOT EXISTS idx_notifications_sent_at ON notifications(sent_at DESC);

-- Función para limpiar tokens antiguos (más de 90 días sin uso)
CREATE OR REPLACE FUNCTION cleanup_old_fcm_tokens()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM fcm_tokens
    WHERE last_used_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Comentarios para documentación
COMMENT ON TABLE fcm_tokens IS 'Almacena tokens FCM de dispositivos para envío de notificaciones push';
COMMENT ON TABLE notifications IS 'Registro de notificaciones enviadas para análisis y debugging';
COMMENT ON FUNCTION cleanup_old_fcm_tokens IS 'Elimina tokens FCM que no se han usado en más de 90 días';

-- Row Level Security (RLS) - Opcional
-- Habilitar RLS en las tablas
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Política para permitir insert/update de tokens (sin autenticación para simplicidad)
CREATE POLICY "Allow public insert on fcm_tokens" 
ON fcm_tokens FOR INSERT 
TO anon 
WITH CHECK (true);

CREATE POLICY "Allow public update on fcm_tokens" 
ON fcm_tokens FOR UPDATE 
TO anon 
USING (true);

-- Política para lectura de notificaciones (público)
CREATE POLICY "Allow public read on notifications" 
ON notifications FOR SELECT 
TO anon 
USING (true);

-- Solo authenticated users pueden insertar notificaciones
CREATE POLICY "Allow authenticated insert on notifications" 
ON notifications FOR INSERT 
TO authenticated 
WITH CHECK (true);
