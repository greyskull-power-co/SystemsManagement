#1. open a powershell window with administrative privileges and run the following
#First create a secure password for connecting to the email notification account.
#This file needs to live in the same folder as the other scripts!

"myPassword" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "E:\scripts\emailpw.txt"

#2. establish event logging capabilities for AccountCreator
#You can create a event viewer filter for message id's 10 and 12 to see information and errors respectively

New-EventLog –LogName Application –Source "AccountCreator"

#3. In task scheduler, schedule accountCreator.bat to run shortly after your file arrives via FTP to the imports folder.

#4. The script will then check for a file E:\imports\today.txt, and compare it's date to today.
#If the file is not from today, an error will be generated to event viewer, and an email sent to helpdesk.
#If the file IS from today, it will check for students in the 'today' file that were not in the 'yesterday' file.
#These additions are then compiled into a csv with headers uid, fname, lname, yog
#Each row is checked, if there is a uid, it is assumed this account is clear to create.
#The current month is checked. They are assigned a grade band (elementary or upper) depending on their YOG and the current month.
#We do this as k-5 are not permitted email and need a different grouping.
#A confirmation event log is written, and confirmation email sent out to guidance(?)
#If there is NOT a UID, it is assumed this is an incomplete registration, and ignored. Warning written to event logs.
#Additional:
#If an account already exists, *anywhere* in your directory, it will NOT be recreated.
#at the end of the year, you simply create new OU for the incoming preschool or pre-reg YOG (I go several years out for pre reg)
#if you have an elementary/upper separation, drag the 'graduating' 5th graders out of your elementary OU, allowing them email access if configured with google ad sync.


