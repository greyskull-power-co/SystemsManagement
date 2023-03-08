#this check makes sure your file export from your SIS was successful for the current day
if( (Get-Date).day - ((ls [your path here]\todayStaff.txt).LastWriteTime).day -eq 0 ){
    $yest = Get-Content "[your path here]\yesterdayStaff.txt"
    $toda = Get-Content "[your path here]\todayStaff.txt"
    $temporaryPW = "[your temporary password]"
    $localDomain = "@[your active directory domain]"
    $emailDomain = "@[your email domain]"
    $addToAllStaff = "[your email allstaff group]"
    $addToStaff = "[your AD faculty group for computer permissions]" 

#find the differences between today, and yesterday, send them to a text file
    $staffDiff = "[your path here]\staffDiff.txt"
    $toda | Where-Object { $_ -notin $yest} > $staffDiff

#modify that text file to become a csv file with headers of your choice
    "lname,fname,type,dept,building,dateofhire,status,email,id,personalmail`n" + (Get-Content $staffDiff | Out-String) | Set-Content $staffDiff
    Copy-Item $staffDiff "[your path here]\staffDiff.csv"

    $csv = Import-Csv "[your path here]\staffDiff.csv"
    $rowCount = $csv | Measure-Object | Select-Object -expand count

#this check makes sure not too many records are changed at once, preventing an account modification meltdown
if($rowCount -lt 21) {

    $csv | ForEach-Object {
    $lname = $_.lname -replace '[\\/]',''
    $upn = $_.fname.ToLower().SubString(0,1) + $lname.ToLower() + $localDomain
    $status = $_.status
    $name = $_.fname + " " + $lname
    $givenName = $_.fname
    $surName = $lname
#note this formulates the username John Smith to jsmith
    $samAcctName = $_.fname.ToLower().SubString(0,1) + $lname.ToLower()
    $email = $_.email
    $type = $_.type
    $dept = $_.dept
    $building = $_.building
    $status = $_.status
    $id = $_.id
    $personalEmail = $_.personalmail
    Write-Debug("less than 20 records, ok to proceed”)
    Write-Debug("user status is $status, username is $samAcctName, email is $email, type is $type, building is $building, and id number is $id")


#additional group memberships, must make these as distribution groups in AD before running.
#this checks for group names based on what comes out of your SIS export that was parsed into a cvs above

 #if type -eq custodian etc.
if($type -eq "Student Teacher"){$addType = "studentteach"}
if($type -eq "Sub - Nurse"){$addType = "subnurse"}
if($type -eq "Teacher"){$addType = "teacher"}
#departments
if($dept -eq "Academic Coach"){$addDept = "acadcoach"}
if($dept -eq "Art"){$addDept = "art"}
if($dept -eq "Art Dept Chair"){$addDept = "art"}
if($dept -eq "Bus/FCS Dept Chair"){$addDept = "fcs"}
if($dept -eq "Business"){$addDept = "business"}


#here you can sort out types into different org units. Helpful is you only license some users with google enterprise
#again building1, building2 etc are active directory distribution groups you would set up prior

    if($building -eq "[Building 1 Name from SIS]”) {
        $addBuilding = "[building1]"
#you can manually punch in secretaries here and it will pass as a variable to your invoke email commands below, not necessary though. Maybe your tech department gets these.
        $secretary = "secretary1@yourEmailDomain.com","secretary2@yourEmailDomain.com"
	    if($type -eq "Teacher"){
            $path = "OU=enterpriseAllowed,OU=building1OrgUnit,OU=FacultyOrgUnit,DC=your,DC=domain”
	    }
	    else {
            $path = "OU=enterpriseNotAllowed,OU=building1OrgUnit,OU=FacultyOrgUnit,DC=your,DC=domain”
        }
    }

    if($building -eq "[Building 2 Name from SIS]") {
        $addBuilding = "[building2]"
        $secretary = "secretary1@yourEmailDomain.com","secretary2@yourEmailDomain.com"
	    if($type -eq "Teacher"){
            $path = "OU=enterpriseAllowed,OU=building2OrgUnit,OU=FacultyOrgUnit,DC=your,DC=domain”
	    }
	    else {
            $path = "OU=enterpriseNotAllowed,OU=building2OrgUnit,OU=FacultyOrgUnit,DC=your,DC=domain”
        }
    }

    
    Write-Debug("Secretary is $secretary")
#if the staff has an email listed, they are determined to be complete and will successfully add to active directory
$ExistingADUser = Get-ADuser -Filter "SamAccountName -eq '$samAcctName'"
#first check if username already exists
if($null -eq $ExistingADUser){
    Write-Debug("no existing AD user, check if ID exists")
#if the username does not yet exists, check if the user id exists.
#if the userid does not exist, then proceed to create user.
$ExistingUserId = Get-ADUser -LDAPFilter "(wWWHomePage=$id)"
    if($null -eq $ExistingUserId){
    Write-Debug("no existing user ID")
        if($email -And $status -eq "Active"){
        Write-Debug("email exists, user status is active")
            New-ADUser -Name $name `
            -GivenName $givenName `
            -Surname $surName `
            -SamAccountName  $samAcctName `
            -UserPrincipalName  $upn `
            -EmailAddress  $email `
            -Path $path `
            -AccountPassword (ConvertTo-SecureString $temporaryPW -AsPlainText -force) -Enabled $true
            Write-Debug("$samAcctName created!!")
            Set-ADUser -ChangePasswordAtLogon $true -Identity $samAcctName
            Add-ADGroupMember -Identity $addToAllStaff -Members $samAcctName
            Add-ADGroupMember -Identity $addToStaff -Members $samAcctName
            if($addType){
                Add-ADGroupMember -Identity $addType -Members $samAcctName
            }
            if($addDept){
                Add-ADGroupMember -Identity $addDept -Members $samAcctName
            }
            if($type -eq "[type that rotates through multiple buildings]"){
	#here you can add additional types in your SIS where you have users that work between buildings like maintenance
                Add-ADGroupMember -Identity "[building2]" -Members $samAcctName
                Add-ADGroupMember -Identity "[building1]" -Members $samAcctName
            }
	#this is a trick you can use to utilize the user ID number from your SIS for preventing duplicate username blow ups - the webpage field in AD
            Set-ADUser -HomePage $id -Identity $samAcctName
        
            if($addBuilding){
                Add-ADGroupMember -Identity $addBuilding -Members $samAcctName
                Write-Debug("added building $building to user $samAcctName")
            }

#An event log is written
            Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Information -Message "Added $name : $samAcctName"
            Invoke-Expression "[your path here]\staffAccountCreationEmail.ps1 $email"
        }
    }
    if($ExistingUserId){
        Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Information -Message "unable to update $name : $samAcctName matches another user ID"
#person does not exist by username, but does exist by user id
        Write-Debug("user $samAcctName user doesn't exist, but another user with the user ID does!")
        Invoke-Expression "[your path here]\surnameConflictEmail.ps1 $email"
    }
}
if($ExistingADUser){
#REMOVE THE USER IF THEY NO LONGER WORK HERE - WILL SUSPEND EMAIL
    if($status -eq "Inactive"){
        Remove-ADUser -Identity $samAcctName -Confirm:$false
#email data manager about deletion
Invoke-Expression "[your path here]\accountDeletionEmail.ps1 $email"
        Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Information -Message "Deleted $name : $samAcctName due to inactive status"
    }
    if($status -eq "Active"){
#if ID matches, modify
$UsersIdNumber = Get-ADUser -Identity $samAcctName -Properties wWWHomePage | Select-Object -ExpandProperty wWWHomePage
        if($id -eq $UsersIdNumber){
            $ADgroups = Get-ADPrincipalGroupMembership -Identity $ExistingADUser | where {$_.Name -ne "Domain Users"}
            Write-Host("account exists! " + $ExistingADUser + " " + $ADgroups)
    #REMOVE GROUPS FROM EXISTING USER CHANGING ROLES (excluding domain users)
            if($ADgroups -ne $null){
                Remove-ADPrincipalGroupMembership -Identity $ExistingADUser -MemberOf $ADgroups -Confirm:$false
            }
    #REBUILD GROUPS FOR EXISTING USER, ADD GROUPS FOR NEW USER
        #required for allstaff and login capabilities
            Add-ADGroupMember -Identity $addToAllStaff -Members $samAcctName
            Add-ADGroupMember -Identity $addToStaff -Members $samAcctName
            if($addBuilding){
                Add-ADGroupMember -Identity $addBuilding -Members $samAcctName
            }
            if($addType){
                Add-ADGroupMember -Identity $addType -Members $samAcctName
            }
            if($addDept){
                Add-ADGroupMember -Identity $addDept -Members $samAcctName
            }
            if($type -eq "[type that rotates through multiple buildings]"){
#here you can add additional types in your SIS where you have users that work between buildings like maintenance
                Add-ADGroupMember -Identity "[building2]" -Members $samAcctName
                Add-ADGroupMember -Identity "[building1]" -Members $samAcctName
            }
    #MOVE THE USER
	        $user = Get-ADUser -Filter "SamAccountName -eq '$samAcctName'" -Properties DisplayName
	        $user | Move-ADObject -TargetPath $path  
            Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Information -Message "Modified $name : $samAcctName to update new change in work status"
            Invoke-Expression "[your path here]\accountModificationEmail.ps1 $email"
    }
        if($id -ne $UsersIdNumber){
            #ERROR - DUPLICATE SAMACCT due to same initials/lastname send email
Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 10 -EntryType Information -Message "Potential duplicate, new account $name with ID $id matches existing account name with different ID number: $UsersIdNumber"
            Invoke-Expression "[your path here]\duplicateAccountNameEmail.ps1 $email"
        }
    }
#IF ID DOES NOT MATCH Email Alert
}

}

#rotate out the old files, not necessary but nice to look at in case of an issue
    Remove-Item -Path "[your path here]\sixDaysAgoStaff.txt"
    Rename-Item -Path "[your path here]\fiveDaysAgoStaff.txt" -NewName "sixDaysAgoStaff.txt"
    Rename-Item -Path "[your path here]\fourDaysAgoStaff.txt" -NewName "fiveDaysAgoStaff.txt"
    Rename-Item -Path "[your path here]\threeDaysAgoStaff.txt" -NewName "fourDaysAgoStaff.txt"
    Rename-Item -Path "[your path here]\twoDaysAgoStaff.txt" -NewName "threeDaysAgoStaff.txt"
    Rename-Item -Path "[your path here]\yesterdayStaff.txt" -NewName "twoDaysAgoStaff.txt"
    Rename-Item -Path "[your path here]\todayStaff.txt" -NewName "yesterdayStaff.txt"
    }
if($rowCount -gt 20 ){
#    $staffErrorEmail = "[your path here]\staffErrorEmail.ps1"
#    &$staffErrorEmail
Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 12 -EntryType Error -Message "too many staff diff records - notifying helpdesk"
 Invoke-Expression "[your path here]\tooManyChangesEmail.ps1 $email"
    }
}else {
#file from SIS ftp is not from today - file an error log and send email to tech team
    Write-EventLog -LogName "Application" -Source "AccountCreator" -EventID 12 -EntryType Error -Message "today's staff ftp file is not from today"

#FAILURE EMAIL HERE
#REMOVED FOR TESTING
    $errorEmail = "[your path here]\staffErrorEmail.ps1"
    &$errorEmail
}
