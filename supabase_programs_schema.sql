-- ===================================
-- ATESUR APP V4 - PROGRAMACIÓN DEL CANAL
-- Tabla para gestionar la programación semanal
-- ===================================

-- Tabla de programas
CREATE TABLE IF NOT EXISTS programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Información del programa
    title TEXT NOT NULL,
    description TEXT,
    category TEXT CHECK (category IN ('noticias', 'deportes', 'entretenimiento', 'cultura', 'educacion', 'otro')),
    
    -- Horario
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    -- 0 = Domingo, 1 = Lunes, 2 = Martes, 3 = Miércoles, 4 = Jueves, 5 = Viernes, 6 = Sábado
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- Información adicional
    host TEXT, -- Conductor del programa
    image_url TEXT, -- URL de la imagen/poster del programa
    is_live BOOLEAN DEFAULT false, -- Si está en vivo ahora
    is_active BOOLEAN DEFAULT true, -- Si el programa está activo en la programación
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_programs_day_of_week ON programs(day_of_week);
CREATE INDEX IF NOT EXISTS idx_programs_start_time ON programs(start_time);
CREATE INDEX IF NOT EXISTS idx_programs_is_active ON programs(is_active);
CREATE INDEX IF NOT EXISTS idx_programs_category ON programs(category);

-- Índice compuesto para búsqueda por día y hora
CREATE INDEX IF NOT EXISTS idx_programs_day_time ON programs(day_of_week, start_time);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
CREATE TRIGGER update_programs_updated_at
    BEFORE UPDATE ON programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para documentación
COMMENT ON TABLE programs IS 'Programación semanal del canal de TV';
COMMENT ON COLUMN programs.day_of_week IS '0=Domingo, 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado';
COMMENT ON COLUMN programs.is_live IS 'Indica si el programa está actualmente en vivo';

-- Row Level Security (RLS)
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

-- Política para lectura pública
CREATE POLICY "Allow public read on programs" 
ON programs FOR SELECT 
TO anon, authenticated
USING (is_active = true);

-- Solo usuarios autenticados pueden gestionar programas
CREATE POLICY "Allow authenticated insert on programs" 
ON programs FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Allow authenticated update on programs" 
ON programs FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Allow authenticated delete on programs" 
ON programs FOR DELETE 
TO authenticated 
USING (true);

-- ===================================
-- DATOS DE EJEMPLO (Opcional)
-- ===================================
-- Descomentar para insertar programación de ejemplo

/*
INSERT INTO programs (title, description, category, day_of_week, start_time, end_time, host, is_active) VALUES
-- Lunes
('Noticiero Matinal', 'Noticias de la mañana', 'noticias', 1, '07:00:00', '09:00:00', 'Juan Pérez', true),
('Deportes en Vivo', 'Resumen deportivo', 'deportes', 1, '20:00:00', '21:00:00', 'María García', true),

-- Martes
('Noticiero Matinal', 'Noticias de la mañana', 'noticias', 2, '07:00:00', '09:00:00', 'Juan Pérez', true),
('Cine del Martes', 'Películas clásicas', 'entretenimiento', 2, '21:00:00', '23:00:00', null, true),

-- Miércoles
('Noticiero Matinal', 'Noticias de la mañana', 'noticias', 3, '07:00:00', '09:00:00', 'Juan Pérez', true),
('Cultura y Arte', 'Programa cultural', 'cultura', 3, '19:00:00', '20:00:00', 'Ana López', true),

-- Jueves
('Noticiero Matinal', 'Noticias de la mañana', 'noticias', 4, '07:00:00', '09:00:00', 'Juan Pérez', true),
('Educación al Día', 'Contenido educativo', 'educacion', 4, '15:00:00', '16:00:00', 'Dr. Carlos Ruiz', true),

-- Viernes
('Noticiero Matinal', 'Noticias de la mañana', 'noticias', 5, '07:00:00', '09:00:00', 'Juan Pérez', true),
('Viernes de Variedades', 'Entretenimiento familiar', 'entretenimiento', 5, '21:00:00', '23:00:00', 'Varios', true),

-- Sábado
('Desayuno Informativo', 'Noticias del fin de semana', 'noticias', 6, '08:00:00', '10:00:00', 'Laura Martínez', true),
('Deportes del Sábado', 'Fútbol en vivo', 'deportes', 6, '15:00:00', '18:00:00', 'Roberto Sánchez', true),

-- Domingo
('Misa Dominical', 'Transmisión de misa', 'cultura', 0, '10:00:00', '11:00:00', null, true),
('Cine Familiar', 'Películas para toda la familia', 'entretenimiento', 0, '16:00:00', '18:00:00', null, true);
*/
