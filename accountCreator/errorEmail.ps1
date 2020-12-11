
#this is your 'dummy' email or a noreply you preconfigure
$User = "noreply@gmail.com”
#get your hashed email password - must be retrieved from the same account that hashed the password
$File = "E:\scripts\emailpw.txt"
#decrypt email password
$cred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)
#send this to your helpdesk or tech team, separated by commas
$EmailTo = “whoever@gmail.com”
#set a displayname [optional]
$EmailFrom = “noreply@gmail.com“
#configure your email here
$Subject = "Error creating new students" 
$Body = "There was an error creating new students, likely from the import file age. Check the server event log for more details." 
#set smtp server
$SMTPServer = "smtp.gmail.com" 
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
#specify port
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password); 
$SMTPClient.Send($SMTPMessage)
