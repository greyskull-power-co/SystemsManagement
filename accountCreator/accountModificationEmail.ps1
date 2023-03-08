        $User = "notifications@yourschool.k12.ma.us"
        #get your hashed email password - must be retrieved from the same account that hashed the password
        $File = "locationOfYourHashedPW\emailpw.txt"
        #decrypt email password
        $cred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)
        #send this to your helpdesk or tech team, separated by commas
        $EmailToAddresses = @("tech1@yourschool.k12.ma.us","tech2@yourschool.k12.ma.us")
        #set a displayname [optional]
        $EmailFrom = "notifications@yourschool.k12.ma.us"
        #configure your email here
        $Subject = "Staff member $samAcctName account modified" 
        $Body = "The staff member identified by email $email was modified to reflect the type: $type, and building: $building. Modifications can come when a user changes buildings or employment types, such as moving from a paraprofessional to a teacher." 
        #set smtp server
        $SMTPServer = "smtp.gmail.com"

        foreach ($EmailTo in $EmailToAddresses){ 
            $SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
            #specify port
            $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
            $SMTPClient.EnableSsl = $true 
            $SMTPClient.Credentials = New-Object System.Net.NetworkCredential($cred.UserName, $cred.Password); 
            $SMTPClient.Send($SMTPMessage)
        }
