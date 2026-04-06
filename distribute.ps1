# distribute.ps1 — build + upload Firebase App Distribution
# Uso: .\distribute.ps1
# Requer: Java 17 (Android Studio) e firebase login feito

$JAVA_HOME = "E:\androidstudio2021\jbr"
$env:JAVA_HOME = $JAVA_HOME
$env:PATH = "$JAVA_HOME\bin;$env:PATH"

$ROOT    = $PSScriptRoot
$APK_SRC = "$ROOT\build\app\outputs\flutter-apk\app-release.apk"
$APK_DST = "$ROOT\build\app\outputs\apk\release\app-release.apk"

Write-Host "`n=== 1/3  Build Flutter APK ===" -ForegroundColor Cyan
Set-Location $ROOT
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Write-Host "Build falhou." -ForegroundColor Red; exit 1 }

Write-Host "`n=== 2/3  Copia APK para saida do Gradle ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path (Split-Path $APK_DST) | Out-Null
Copy-Item -Force $APK_SRC $APK_DST
Write-Host "APK copiado: $APK_DST"

Write-Host "`n=== 3/3  Upload Firebase App Distribution ===" -ForegroundColor Cyan
Set-Location "$ROOT\android"
# -x assembleRelease pula o build do Gradle e usa o APK Flutter copiado acima
./gradlew appDistributionUploadRelease -x assembleRelease
if ($LASTEXITCODE -ne 0) { Write-Host "Upload falhou." -ForegroundColor Red; exit 1 }

Write-Host "`nDistribuicao concluida!" -ForegroundColor Green
Set-Location $ROOT
