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
