# Script de Configuración de Estructura de Carpetas - atesur_app_v4
# Autor: Antigravity AI Assistant
# Descripción: Crea toda la estructura de carpetas necesaria para el proyecto Flutter

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  ATESUR APP V4 - Setup Script" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Función para crear carpetas
function Create-Folder {
    param (
        [string]$Path
    )
    
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[✓] Creada: $Path" -ForegroundColor Green
    } else {
        Write-Host "[~] Ya existe: $Path" -ForegroundColor Yellow
    }
}

Write-Host "Creando estructura de carpetas..." -ForegroundColor Cyan
Write-Host ""

# Core (configuración central)
Create-Folder "lib/src/core/config"
Create-Folder "lib/src/core/theme"
Create-Folder "lib/src/core/router"
Create-Folder "lib/src/core/services"
Create-Folder "lib/src/core/constants"
Create-Folder "lib/src/core/utils"

# Common/Shared (widgets compartidos)
Create-Folder "lib/src/common/widgets"
Create-Folder "lib/src/common/models"

# Features - Player (Reproductor)
Create-Folder "lib/src/features/player/models"
Create-Folder "lib/src/features/player/services"
Create-Folder "lib/src/features/player/providers"
Create-Folder "lib/src/features/player/widgets"
Create-Folder "lib/src/features/player/screens"

# Features - News (Noticias)
Create-Folder "lib/src/features/news/models"
Create-Folder "lib/src/features/news/services"
Create-Folder "lib/src/features/news/providers"
Create-Folder "lib/src/features/news/widgets"
Create-Folder "lib/src/features/news/screens"

# Features - Social (Redes Sociales)
Create-Folder "lib/src/features/social/models"
Create-Folder "lib/src/features/social/widgets"
Create-Folder "lib/src/features/social/screens"

# Features - Contact (Contacto)
Create-Folder "lib/src/features/contact/models"
Create-Folder "lib/src/features/contact/services"
Create-Folder "lib/src/features/contact/providers"
Create-Folder "lib/src/features/contact/widgets"
Create-Folder "lib/src/features/contact/screens"

# Features - Shell (Layout principal)
Create-Folder "lib/src/features/shell/widgets"
Create-Folder "lib/src/features/shell/screens"

# Assets (recursos)
Create-Folder "assets/images"
Create-Folder "assets/icons"
Create-Folder "assets/fonts"
Create-Folder "assets/data"

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  ✓ Estructura creada exitosamente" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. Ejecutar: flutter pub get" -ForegroundColor White
Write-Host "2. Configurar archivo .env con tus credenciales" -ForegroundColor White
Write-Host "3. Comenzar desarrollo" -ForegroundColor White
Write-Host ""
