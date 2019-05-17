#.csv file must be in the format:
#USERID,FirstName,LastName,YOG
#if the import is from the current day, proceed
if( (Get-Date).day - ((ls E:\imports\today.txt).LastWriteTime).day -eq 0 ){
    $yest = Get-Content "E:\imports\yesterday.txt"
    $toda = Get-Content "E:\imports\today.txt"

#this will generate a temporary password for the accounts
    $temporaryPW = "tempPassword"
#change this to your domain
    $localDomain = "@yourdomain.priv"
#change this to what group you want the users in
    $addToGroup = "securityGroup"

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
#if it's before or after July, make the appropriate YOG class calculation

    if($currentMonth -gt 7) {
        $monthAdjustment = 8
    }
    if($currentMonth -le 7){
        $monthAdjustment = 7
    }

    $elementary = [int]$currentYear + [int]$monthAdjustment
    $csv | ForEach-Object {
    $upn = $_.fname.ToLower().SubString(0,1) + $_.lname.ToLower().SubString(0,1) + $_.uid + $localDomain
    $localId = [int]$_.uid
    $name = $_.fname + " " + $_.lname
    $givenName = $_.fname
    $surName = $_.lname
    $samAcctName = $_.fname.ToLower().SubString(0,1) + $_.lname.ToLower().SubString(0,1) + $_.uid

#optional - if you would like to separate your org units by YOG
#otherwise, just set one $path variable

    if($_.yog -gt $elementary) {
        $path = "OU=" + $_.yog + ",OU=ElemStudent,OU=Student,DC=yourdomain,DC=priv"
    }
    else {
        $path = "OU=" + $_.yog + ",OU=Student,DC=yourdomain,DC=priv"
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
#file from SIS ftp is not from today - file an error log and send email to tech team
    Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 12 -EntryType Error -Message "today's ftp file is not from today"

#FAILURE EMAIL HERE
    $errorEmail = "E:\scripts\errorEmail.ps1"
    &$errorEmail
}
