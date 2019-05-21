#.csv file must be in the format:
#USERID,FirstName,LastName,YOG
#if the import is from the current day, proceed
if( (Get-Date).day - ((ls E:\imports\today.txt).LastWriteTime).day -eq 0 ){
    $yest = Get-Content "E:\imports\yesterday.txt"
    $toda = Get-Content "E:\imports\today.txt"

#configure your temporary password, domain, and a group of your choosing ie. student
    $temporaryPW = "tempPasswordHere"
    $localDomain = "@domain.priv"
    $addToGroup = "student"

#find the differences between today, and yesterday, send them to a text file
    $diff = "E:\scripts\diff.txt"
    $toda | Where-Object { $_ -notin $yest} > $diff

#modify that text file to become a csv file with headers
    "uid,fname,lname,yog`n" + (Get-Content $diff | Out-String) | Set-Content $diff
    Copy-Item $diff "E:\scripts\diff.csv"

    $csv = Import-Csv "E:\scripts\diff.csv"
    $currentYear = get-date -Format yyyy
    $currentMonth = get-date -UFormat "%m"

#this is the grade year split adjustment
#greater than july
    if($currentMonth -gt 7) {
        $monthAdjustment = 8
    }
#less than july
    if($currentMonth -le 7){
        $monthAdjustment = 7
    }

#calculate the YOG split from grade 5 to grade 6
    $elementary = [int]$currentYear + [int]$monthAdjustment
    $csv | ForEach-Object {
#we lowercase the first and last name, then take the initials and add them to a lasid to give us something like js2012345
    $upn = $_.fname.ToLower().SubString(0,1) + $_.lname.ToLower().SubString(0,1) + $_.uid + $localDomain
    $localId = [int]$_.uid
    $name = $_.fname + " " + $_.lname
    $givenName = $_.fname
    $surName = $_.lname
    $samAcctName = $_.fname.ToLower().SubString(0,1) + $_.lname.ToLower().SubString(0,1) + $_.uid

#configure the path to match your active directory OU setup
#this will (depending on the month) decide if your org is pk-5 or 6-12
#if you do not want to separate elementary from upper levels, simply use one path variable
#$path = "OU=" + $_.yog + ",OU=Student,DC=domain,DC=priv"

    if($_.yog -gt $elementary) {
        $path = "OU=" + $_.yog + ",OU=Elem Student,OU=Student,DC=domain,DC=priv"
    }
    else {
        $path = "OU=" + $_.yog + ",OU=Student,DC=domain,DC=priv"
    }

#if the student has a local ID, they are determined to be complete and will successfully add to active directory
    if($localId){
        New-ADUser -Name $name `
         -GivenName $givenName `
         -Surname $surName `
         -SamAccountName  $samAcctName `
         -UserPrincipalName  $upn `
         -Path $path `
         -AccountPassword (ConvertTo-SecureString $temporaryPW -AsPlainText -force) -Enabled $true
#change pw at first login
        Set-ADUser -ChangePasswordAtLogon $true -Identity $samAcctName
#add the user to the specified group
        Add-ADGroupMember -Identity $addToGroup -Members $samAcctName

#An event log is written
        Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Information -Message "Added $name : $samAcctName"

#Send an email of success here
        $successEmail = "E:\scripts\successEmail.ps1"
        &$successEmail

}
#if the student does NOT have a local ID, they are determined incomplete and a warning log is written
    if(!$localId){
        Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Warning -Message "No user ID for $name : could not create!"
    }
}
#rotate out the old files, not necessary but nice to look at in case of an issue
    Remove-Item -Path "E:\imports\sixDaysAgo.txt"
    Rename-Item -Path "E:\imports\fiveDaysAgo.txt" -NewName "sixDaysAgo.txt"
    Rename-Item -Path "E:\imports\fourDaysAgo.txt" -NewName "fiveDaysAgo.txt"
    Rename-Item -Path "E:\imports\threeDaysAgo.txt" -NewName "fourDaysAgo.txt"
    Rename-Item -Path "E:\imports\twoDaysAgo.txt" -NewName "threeDaysAgo.txt"
    Rename-Item -Path "E:\imports\yesterday.txt" -NewName "twoDaysAgo.txt"
    Rename-Item -Path "E:\imports\today.txt" -NewName "yesterday.txt"

}else {
#file from SIS ftp is not from today - file an error log ID 12 and send email to tech team
    Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 12 -EntryType Error -Message "today's ftp file is not from today"

#FAILURE EMAIL HERE
    $errorEmail = "E:\scripts\errorEmail.ps1"
    &$errorEmail
}
