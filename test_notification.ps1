# Script para probar la funcion Edge de notificaciones FCM
# Asegurate de actualizar SUPABASE_ANON_KEY con tu clave real desde el Dashboard

param(
    [string]$Title = "Prueba de Notificacion",
    [string]$Body = "Esta es una notificacion de prueba desde Supabase Edge Function",
    [string]$Type = "general"
)

# ============================================
# CONFIGURACION - ACTUALIZA ESTOS VALORES
# ============================================
$SUPABASE_URL = "https://kholyiqxboourdwavkci.supabase.co"
$SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtob2x5aXF4Ym9vdXJkd2F2a2NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyMzQ3MzcsImV4cCI6MjA4MTgxMDczN30.4Si0xrOmlnMRtG22IVy83qdZ5eDdR5DmSM2Z1hhCIFE"

# ============================================
# ENVIAR NOTIFICACION
# ============================================
Write-Host "[>] Enviando notificacion..." -ForegroundColor Cyan
Write-Host "    Titulo: $Title" -ForegroundColor Gray
Write-Host "    Cuerpo: $Body" -ForegroundColor Gray
Write-Host "    Tipo: $Type" -ForegroundColor Gray
Write-Host ""

$headers = @{
    "Authorization" = "Bearer $SUPABASE_ANON_KEY"
    "Content-Type"  = "application/json"
    "apikey"        = "$SUPABASE_ANON_KEY"
}

$body = @{
    title = $Title
    body  = $Body
    type  = $Type
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod `
        -Uri "$SUPABASE_URL/functions/v1/send-notification" `
        -Method POST `
        -Headers $headers `
        -Body $body
    
    Write-Host "[OK] Notificacion enviada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Resultados:" -ForegroundColor Yellow
    Write-Host "  Enviadas: $($response.sentTo)" -ForegroundColor Green
    Write-Host "  Total: $($response.total)" -ForegroundColor Cyan
    Write-Host "  Fallidas: $($response.failed)" -ForegroundColor $(if ($response.failed -gt 0) { "Red" } else { "Gray" })
    Write-Host ""
    
}
catch {
    Write-Host "[ERROR] Error al enviar notificacion" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifica que:" -ForegroundColor Yellow
    Write-Host "  1. SUPABASE_ANON_KEY este configurada correctamente" -ForegroundColor Gray
    Write-Host "  2. Los Firebase Secrets esten configurados en Supabase" -ForegroundColor Gray
    Write-Host "  3. Existan tokens FCM en la tabla fcm_tokens" -ForegroundColor Gray
}

# ============================================
# USO
# ============================================
# Ejecutar con parametros personalizados:
# .\test_notification.ps1 -Title "Hola" -Body "Mensaje personalizado" -Type "news"
