# Fixes corrupted Gradle wrapper cache and pre-downloads Gradle 8.13 (Windows).
# Run from project root:  powershell -ExecutionPolicy Bypass -File scripts\setup_android_build.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$GradleVersion = "8.13"
$GradleZipName = "gradle-$GradleVersion-bin.zip"
$GradleUrl = "https://services.gradle.org/distributions/$GradleZipName"
$GradleSha256 = "20f1b1176237254a6fc204d8434196fa11a4cfb387567519c61556e8710aed78"

Write-Host "==> Clearing corrupted Gradle wrapper cache..."
$dists = "$env:USERPROFILE\.gradle\wrapper\dists"
if (Test-Path $dists) {
    Get-ChildItem $dists -Directory | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "==> Downloading Gradle $GradleVersion (via Windows TLS)..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$zipPath = "$env:TEMP\$GradleZipName"
Invoke-WebRequest -Uri $GradleUrl -OutFile $zipPath -UseBasicParsing

$sha = [System.Security.Cryptography.SHA256]::Create()
$actualHash = -join ($sha.ComputeHash([IO.File]::ReadAllBytes($zipPath)) | ForEach-Object { $_.ToString("x2") })
if ($actualHash -ne $GradleSha256) {
    throw "Gradle zip SHA256 mismatch. Expected $GradleSha256 got $actualHash"
}

# Gradle 8+ uses distributionSha256Sum as the cache subfolder name.
$destDir = "$dists\gradle-$GradleVersion-bin\$GradleSha256"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item $zipPath "$destDir\$GradleZipName" -Force

# Leave only the zip + .ok marker; Gradle wrapper will unzip on first run.
New-Item -ItemType File -Path "$destDir\$GradleZipName.ok" -Force | Out-Null

Write-Host "==> Flutter clean + pub get..."
Set-Location $ProjectRoot
flutter clean | Out-Host
flutter pub get | Out-Host

$jbr = "C:\Program Files\Android\Android Studio\jbr"
$javaExe = "$jbr\bin\java.exe"
if (Test-Path $javaExe) {
    Write-Host "==> Using Android Studio JDK for Gradle..."
    $env:JAVA_HOME = $jbr
}

Write-Host "==> Verifying Gradle..."
Set-Location "$ProjectRoot\android"
& .\gradlew.bat --version | Out-Host

Write-Host "==> Building debug APK (flutter build apk --debug)..."
Set-Location $ProjectRoot
flutter build apk --debug | Out-Host

Write-Host ""
Write-Host "Done. Run:  flutter run"
Write-Host "Or:       flutter build appbundle"
