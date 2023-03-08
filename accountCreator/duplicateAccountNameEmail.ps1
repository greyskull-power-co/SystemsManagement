        $User = "notifications@yourschool.k12.ma.us"
        #get your hashed email password - must be retrieved from the same account that hashed the password
        $File = "locationOfYourHashedEmailPW\emailpw.txt"
        #decrypt email password
        $cred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString)
        #send this to your helpdesk or tech team, separated by commas
        $EmailToAddresses = @("helpdesk@yourschool.k12.ma.us")#change this to helpdesk
        #set a displayname [optional]
        $EmailFrom = "notifications@yourschool.k12.ma.us"
        #configure your email here
        $Subject = "Staff member $samAcctName account error" 
        $Body = "The staff member identified by email $email was unable to be created - there is another account with an identical name but different ID number. This could indicate an account name conflict such as katie walker and kerrin walker both wanting to be kwalker, OR the webpage field in Active Directory is missing the users X2 ID number. Compare AD record against X2, and update the ID if necessary, or if a dupliate username, correct this following the manual instructions here https://docs.google.com/[link to your SOP]" 
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
