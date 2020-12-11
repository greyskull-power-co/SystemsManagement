#this will run silently in the background whether the system is in use or not.
#be careful of where you place this, it will aggressively install and restart.
#be careful of when you schedule this, again it will restart and runs without warning the user. If run during the day, it will restart mid day.

$winver = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId

#other version checks you could use:
#returns the product name ex - Windows 10 Pro
$winProdName = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
#returns the 5 digit build number (probably most accurate)
$winBuild = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild

If($winver -lt 1809){
$dir = "c:\temp"
mkdir $dir
$webClient = New-Object System.Net.WebClient
$url = "https://go.microsoft.com/fwlink/?LinkID=799445"
$file = "$($dir)\Win10Upgrade.exe"
$webClient.DownloadFile($url,$file)
Start-Process -FilePath $file -ArgumentList "/quietinstall /skipeula /auto upgrade /copylogs $dir" -verb runas
}

If($winver -ge 1809){
exit
}
