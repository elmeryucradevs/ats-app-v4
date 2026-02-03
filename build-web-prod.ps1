# Variables de entorno para build de producción web
$env_vars = @(
    "STREAM_URL=https://video2.getstreamhosting.com:19360/8016/8016.m3u8"
    "SUPABASE_URL=https://your-project.supabase.co"
    "SUPABASE_ANON_KEY=your-anon-key-here"
    "WORDPRESS_API_URL=https://atesurplus.wordpress.com/wp-json/wp/v2"
    "FACEBOOK_URL=https://facebook.com/atesur"
    "TWITTER_URL=https://twitter.com/atesur"
    "INSTAGRAM_URL=https://instagram.com/atesur"
    "YOUTUBE_URL=https://youtube.com/@atesur"
    "TIKTOK_URL=https://tiktok.com/@atesur"
    "WHATSAPP_URL=https://wa.me/591XXXXXXXX"
    "CONTACT_EMAIL=contacto@atesur.com"
    "DEBUG_MODE=false"
)

# Construir argumentos --dart-define
$dart_defines = $env_vars | ForEach-Object { "--dart-define=$_" }
$command = "flutter build web $($dart_defines -join ' ')"

Write-Host "🚀 Building ATESUR web app with environment variables..."
Write-Host ""
Invoke-Expression $command

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "📁 Output directory: build\web" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To deploy:" -ForegroundColor Yellow
    Write-Host "  1. Upload build\web folder to your hosting"
    Write-Host "  2. Configure Firebase Hosting (optional)"
    Write-Host "  3. Set up custom domain"
} else {
    Write-Host ""
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
