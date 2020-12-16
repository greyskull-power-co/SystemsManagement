#find your county from the county list here https://alerts.weather.gov/
#choose the relevant ATOM rss link, ex here shown hawaii
#https://alerts.weather.gov/cap/wwaatmget.php?x=HIC001&y=0

wget "https://alerts.weather.gov/cap/wwaatmget.php?x=HIC001&y=0" -OutFile C:\Users\Public\weather.html
$weatherWarn = "C:\Users\Public\weather.html"

#specific string patterns to look for, here we are concerned with winter weather and wind
$WSW = Select-String -Path $weatherWarn -Pattern "Winter Storm Warning"
$HWW = Select-String -Path $weatherWarn -Pattern "High Wind Warning"

#this script is run by a 7pm scheduled task
#here is a double check (6:50p-7:40p) to make sure it doesn't go rogue outside that window
$min = Get-Date '18:50'
$max = Get-Date '19:40'
$now = Get-Date

#make sure the file isn't old and erroneously triggering
$lastWrite = (get-item $weatherWarn).LastWriteTime
$timeSpan = new-timespan -hours 24

if (((get-date) - $lastWrite) -gt $timeSpan){
  exit
}else{
  if ($WSW -ne $null -Or $HWW -ne $null){
    if($min.TimeOfDay -le $now.TimeOfDay -And $max.TimeOfDay -ge $now.TimeOfDay){
      Stop-Computer
    }else{
      exit
    }
  }else{
    exit
  }
}
