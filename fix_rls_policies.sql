-- ==============================================================================
-- FIX RLS POLICIES FOR ATESUR CHANNEL EDITOR
-- ==============================================================================
-- El editor de escritorio usa la key 'anon' de Supabase.
-- Las políticas actuales solo permiten escritura a usuarios autenticados.
-- Este script añade políticas para permitir escritura desde el editor.
--
-- EJECUTAR EN: Supabase Dashboard > SQL Editor
-- ==============================================================================

-- 1. Permitir INSERT desde anon (para crear programas)
DROP POLICY IF EXISTS "Allow anon insert on programs" ON programs;
CREATE POLICY "Allow anon insert on programs" 
ON programs FOR INSERT 
TO anon 
WITH CHECK (true);

-- 2. Permitir UPDATE desde anon (para editar programas)
DROP POLICY IF EXISTS "Allow anon update on programs" ON programs;
CREATE POLICY "Allow anon update on programs" 
ON programs FOR UPDATE 
TO anon 
USING (true);

-- 3. Permitir DELETE desde anon (para eliminar programas)
DROP POLICY IF EXISTS "Allow anon delete on programs" ON programs;
CREATE POLICY "Allow anon delete on programs" 
ON programs FOR DELETE 
TO anon 
USING (true);

-- 4. Permitir lectura de programas inactivos también (para el editor)
DROP POLICY IF EXISTS "Allow public read on programs" ON programs;
CREATE POLICY "Allow public read on programs" 
ON programs FOR SELECT 
TO anon, authenticated
USING (true);  -- Cambiado de (is_active = true) a (true) para ver todos

-- ==============================================================================
-- FIX CATEGORY CONSTRAINT - Agregar nuevas categorías
-- ==============================================================================
-- El constraint original solo tiene: noticias, deportes, entretenimiento, cultura, educacion, otro
-- Necesitamos agregar: cine, musica, infantil

-- Primero eliminar el constraint existente
ALTER TABLE programs DROP CONSTRAINT IF EXISTS programs_category_check;

-- Recrear con todas las categorías
ALTER TABLE programs ADD CONSTRAINT programs_category_check 
CHECK (category IN (
  'noticias', 
  'deportes', 
  'entretenimiento', 
  'cultura', 
  'educacion', 
  'cine',
  'musica', 
  'infantil',
  'otro'
));

-- ==============================================================================
-- FIX RLS POLICIES FOR MOVIES DATABASE (NEW)
-- ==============================================================================
-- El editor de escritorio necesita guardar y listar películas registradas localmente en 'movies_database'.
-- Permitimos todas las operaciones (CRUD) desde la clave 'anon'.

-- 1. Permitir SELECT desde anon
DROP POLICY IF EXISTS "Allow anon read on movies_database" ON movies_database;
DROP POLICY IF EXISTS "Admins can manage movies database" ON movies_database; -- Eliminar la anterior política restrictiva si es necesario
CREATE POLICY "Allow anon read on movies_database" 
ON movies_database FOR SELECT 
TO anon, authenticated
USING (true);

-- 2. Permitir INSERT desde anon
DROP POLICY IF EXISTS "Allow anon insert on movies_database" ON movies_database;
CREATE POLICY "Allow anon insert on movies_database" 
ON movies_database FOR INSERT 
TO anon 
WITH CHECK (true);

-- 3. Permitir UPDATE desde anon
DROP POLICY IF EXISTS "Allow anon update on movies_database" ON movies_database;
CREATE POLICY "Allow anon update on movies_database" 
ON movies_database FOR UPDATE 
TO anon 
USING (true);

-- 4. Permitir DELETE desde anon
DROP POLICY IF EXISTS "Allow anon delete on movies_database" ON movies_database;
CREATE POLICY "Allow anon delete on movies_database" 
ON movies_database FOR DELETE 
TO anon 
USING (true);

-- ==============================================================================
