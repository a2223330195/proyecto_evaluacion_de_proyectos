#!/usr/bin/env pwsh
# Script para limpiar coaches y reiniciar la app

Write-Host "🧹 Limpiando tabla de coaches..." -ForegroundColor Yellow

# Ejecutar script SQL para limpiar coaches
$sqlFile = Join-Path $PSScriptRoot "lib/db/reset_coaches.sql"
$sqlContent = Get-Content -Path $sqlFile -Raw
mysql -h localhost -u root -proot coachhub_db -e $sqlContent

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Tabla de coaches limpiada correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Pasos a seguir:" -ForegroundColor Cyan
    Write-Host "1. Abre CoachHub en tu navegador"
    Write-Host "2. Haz clic en 'Regístrate'"
    Write-Host "3. Ingresa un NUEVO usuario (ej: test@coach.com)"
    Write-Host "4. Completa el registro"
    Write-Host "5. Ahora intenta iniciar sesión"
    Write-Host ""
    Write-Host "Si aún se congela, ejecuta: flutter run -v" -ForegroundColor Yellow
    Write-Host "Esto te mostrará los logs de depuración completos"
} else {
    Write-Host "❌ Error al limpiar tabla de coaches" -ForegroundColor Red
}
