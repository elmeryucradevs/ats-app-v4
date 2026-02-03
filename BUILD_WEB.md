# Build Scripts para Web con Variables de Entorno

Este documento explica cómo compilar la app para web con variables de entorno.

## Desarrollo Local (Web)

Para desarrollo local en web, los valores por defecto (`webFallback`) en `EnvConfig` se usarán automáticamente:

```bash
flutter run -d chrome
```

## Build de Producción (Web)

Para producción, usa `--dart-define` para pasar las variables de entorno:

```bash
flutter build web \
  --dart-define=STREAM_URL=https://your-stream.com/stream.m3u8 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=WORDPRESS_API_URL=https://your-wordpress.com/wp-json/wp/v2 \
  --dart-define=FACEBOOK_URL=https://facebook.com/yourpage \
  --dart-define=TWITTER_URL=https://twitter.com/yourpage \
  --dart-define=INSTAGRAM_URL=https://instagram.com/yourpage \
  --dart-define=YOUTUBE_URL=https://youtube.com/@yourpage \
  --dart-define=TIKTOK_URL=https://tiktok.com/@yourpage \
  --dart-define=WHATSAPP_URL=https://wa.me/591XXXXXXXX \
  --dart-define=CONTACT_EMAIL=contacto@atesur.com \
  --dart-define=DEBUG_MODE=false
```

## Script PowerShell para Windows

Crear `build-web-prod.ps1`:

```powershell
# Variables de entorno para build de producción web
$env_vars = @(
    "STREAM_URL=https://video2.getstreamhosting.com:19360/8016/8016.m3u8"
    "SUPABASE_URL=https://your-project.supabase.co"
    "SUPABASE_ANON_KEY=your-anon-key-here"
    "WORDPRESS_API_URL=https://atesurplus.wordpress.com/wp-json/wp/v2"
    "DEBUG_MODE=false"
)

# Construir el comando
$dart_defines = $env_vars | ForEach-Object { "--dart-define=$_" }
$command = "flutter build web $($dart_defines -join ' ')"

Write-Host "🚀 Building web app with environment variables..."
Invoke-Expression $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build completed successfully!"
    Write-Host "📁 Output: build\web"
} else {
    Write-Host "❌ Build failed"
    exit 1
}
```

Ejecutar:
```bash
.\build-web-prod.ps1
```

## Mobile/Desktop

Para mobile y desktop, continúa usando el archivo `.env` como siempre:

```bash
# Android
flutter run

# iOS  
flutter run -d ios

# Windows
flutter run -d windows
```

## Verificar Configuración

Después de iniciar la app, revisa los logs para confirmar que EnvConfig cargó correctamente:

```
[EnvConfig] ✅ Todas las configuraciones cargadas correctamente
[EnvConfig] Configuración actual:
  Plataforma: Web
  Stream URL: ✓
  Supabase URL: ✓
  ...
```
