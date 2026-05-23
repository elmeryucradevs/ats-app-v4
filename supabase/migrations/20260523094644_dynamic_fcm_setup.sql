-- =====================================================================
-- MIGRACIÓN DE BASE DE DATOS: FIREBASE DINÁMICO Y AISLAMIENTO IN-APP
-- =====================================================================

BEGIN;

-- 1. CREACIÓN DE LA TABLA DE CREDENCIALES FIREBASE
CREATE TABLE IF NOT EXISTS public.channel_firebase_configs (
  channel_id uuid PRIMARY KEY REFERENCES public.channels(id) ON DELETE CASCADE,
  project_id text NOT NULL,
  client_email text NOT NULL,
  private_key text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS
ALTER TABLE public.channel_firebase_configs ENABLE ROW LEVEL SECURITY;

-- Crear políticas RLS: Solo accesible por super_admins
DROP POLICY IF EXISTS "Solo super_admins administran channel_firebase_configs" ON public.channel_firebase_configs;
CREATE POLICY "Solo super_admins administran channel_firebase_configs"
  ON public.channel_firebase_configs FOR ALL
  TO authenticated
  USING (public.is_super_admin());

-- 2. ADAPTAR TABLA IN-APP MESSAGES PARA MULTI-TENANCY
-- Añadir columna channel_id si no existe
ALTER TABLE public.inapp_messages ADD COLUMN IF NOT EXISTS channel_id uuid REFERENCES public.channels(id) ON DELETE CASCADE;

-- Realizar backfill para que los mensajes existentes se asocien al canal principal por defecto
UPDATE public.inapp_messages SET channel_id = 'd0000000-0000-0000-0000-000000000000' WHERE channel_id IS NULL;

-- Establecer restricción NOT NULL
ALTER TABLE public.inapp_messages ALTER COLUMN channel_id SET NOT NULL;

-- Habilitar RLS
ALTER TABLE public.inapp_messages ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas públicas anteriores
DROP POLICY IF EXISTS "Allow public read on inapp_messages" ON public.inapp_messages;
DROP POLICY IF EXISTS "Allow anon insert on inapp_messages" ON public.inapp_messages;
DROP POLICY IF EXISTS "Allow anon update on inapp_messages" ON public.inapp_messages;
DROP POLICY IF EXISTS "Allow anon delete on inapp_messages" ON public.inapp_messages;
DROP POLICY IF EXISTS "Usuarios leen mensajes in-app de su canal" ON public.inapp_messages;
DROP POLICY IF EXISTS "Editores modifican mensajes in-app de su canal" ON public.inapp_messages;

-- Crear políticas RLS multi-tenant para inapp_messages
CREATE POLICY "Usuarios leen mensajes in-app de su canal"
  ON public.inapp_messages FOR SELECT
  TO authenticated, anon
  USING (
    public.is_super_admin() OR
    channel_id IN (
      SELECT cu.channel_id FROM public.channel_users cu WHERE cu.user_id = auth.uid()
    ) OR
    auth.role() = 'anon'
  );

CREATE POLICY "Editores modifican mensajes in-app de su canal"
  ON public.inapp_messages FOR ALL
  TO authenticated
  USING (
    public.is_super_admin() OR
    channel_id IN (
      SELECT cu.channel_id FROM public.channel_users cu 
      WHERE cu.user_id = auth.uid() AND cu.role IN ('owner', 'admin', 'editor')
    )
  );

-- Habilitar Realtime para inapp_messages si no está habilitado
-- (Nota: la publicación ya existe en la base de datos, así que solo nos aseguramos de que esté asociada)
ALTER PUBLICATION supabase_realtime ADD TABLE public.inapp_messages;

COMMIT;
