
#this is your 'dummy' or noreply email 
$User = “noreply@gmail.com”
#get your hashed email password - must be retrieved from the same account that hashed the password
$File = "E:\scripts\emailpw.txt"
#decrypt email password
$cred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)
#emails to receive success notifications
$EmailTo = “guidance?@gmail.com”
#set a displayname [optional]
$EmailFrom = “noreply@gmail.com“
#configure your email here
$Subject = "Students successfully added" 
$Body = "Email body text" 
#set smtp server
$SMTPServer = "smtp.gmail.com" 
#include attachements [optional]
$filenameAndPath = "E:\scripts\diff.txt"
$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
$attachment = New-Object System.Net.Mail.Attachment($filenameAndPath)
$SMTPMessage.Attachments.Add($attachment)
#specify port
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
$SMTPClient.EnableSsl = $true 
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password); 
$SMTPClient.Send($SMTPMessage)
