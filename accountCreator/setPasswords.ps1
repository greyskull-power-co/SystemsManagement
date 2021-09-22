$Resetpassword = Import-Csv "E:\yourEnrolledStudentDiff_File"
$ResetPassword | ForEach-Object {
$AccountName = $_.fname.ToLower().Substring(0,1) + $_.lname.ToLower().SubString(0,1) + $_.uid
$APassword = $_.pwd
$AStatus = $_.status

if ($AStatus -eq "Active"){
Set-ADAccountPassword -Identity $AccountName -NewPassword ((ConvertTo-SecureString $APassword -AsPlainText -force)) -Reset
}
}
