-- ==============================================================================
-- SCRIPT DE CONFIGURACIÓN DE SUPABASE (ATESUR APP V4)
-- ==============================================================================

-- 1. Crear la tabla app_config
create table if not exists app_config (
  id bigint primary key generated always as identity,
  stream_url text not null,
  wordpress_url text not null,
  logo_url text,
  created_at timestamptz default now()
);

-- 2. Habilitar Realtime para la tabla (Importante para que la app detecte cambios)
alter publication supabase_realtime add table app_config;

-- 3. Insertar configuración inicial (Asegurarse de que no duplique si ya existe lógica de negocio, 
--    pero para setup inicial es un insert simple)
insert into app_config (stream_url, wordpress_url, logo_url)
values (
  'https://video2.getstreamhosting.com:19360/8016/8016.m3u8', -- Stream por defecto
  'https://atesurplus.wordpress.com/wp-json/wp/v2',          -- WordPress API
  'https://example.com/logo.png'                             -- URL del Logo (Reemplazar con URL real)
);

-- 4. (Opcional) Políticas RLS (Row Level Security)
-- Permitir lectura pública
alter table app_config enable row level security;

create policy "Lectura pública de configuración"
on app_config for select
to anon
using (true);

-- Permitir escritura solo a usuarios autenticados (o admins)
-- Ajustar según tus necesidades de seguridad.
