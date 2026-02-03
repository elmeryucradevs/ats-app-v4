-- ==============================================================================
-- UPDATE SOCIAL MEDIA COLUMNS TO APP_CONFIG
-- ==============================================================================
-- Agrega columnas para redes sociales, TIKTOK y VISIBILIDAD INDIVIDUAL.
-- Habilita REALTIME.
-- 
-- EJECUTAR EN: Supabase Dashboard > SQL Editor
-- ==============================================================================

-- 1. Asegurar columnas de datos (Incluyendo TikTok)
ALTER TABLE app_config 
ADD COLUMN IF NOT EXISTS facebook_url TEXT,
ADD COLUMN IF NOT EXISTS instagram_url TEXT,
ADD COLUMN IF NOT EXISTS twitter_url TEXT,
ADD COLUMN IF NOT EXISTS youtube_url TEXT,
ADD COLUMN IF NOT EXISTS tiktok_url TEXT,
ADD COLUMN IF NOT EXISTS whatsapp_number TEXT,
ADD COLUMN IF NOT EXISTS contact_email TEXT,
ADD COLUMN IF NOT EXISTS website_url TEXT;

-- 2. Eliminar switch global anterior si existe
ALTER TABLE app_config 
DROP COLUMN IF EXISTS show_social_media;

-- 3. Agregar switches individuales (Default TRUE)
ALTER TABLE app_config 
ADD COLUMN IF NOT EXISTS show_facebook BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_instagram BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_twitter BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_youtube BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_tiktok BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_whatsapp BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_email BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS show_website BOOLEAN DEFAULT TRUE;

-- 4. HABILITAR REALTIME
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
COMMIT;

COMMENT ON COLUMN app_config.whatsapp_number IS 'Número de WhatsApp en formato internacional (ej. 59170000000)';
