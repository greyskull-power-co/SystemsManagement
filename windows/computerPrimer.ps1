$adminCheck = read-host 'does this computer need softright? enter y or n'
#this computer requires the softright link and static IP
if ($adminCheck -eq 'y'){
	Write-Host "copying softright"
	$currentName = hostname
	Write-Host "current computer name is $currentName"
	#copy the RDP client to softright so that ALL following users will rec. it
	Copy-Item -Path "$PSScriptRoot\softright.rdp" -Destination "C:\Users\Default\Desktop\"
	#update static IP requirements per your environment
	Write-Host "softright requires a static IP address - 10.x.x.x to 10.x.x.x, please confirm that an address is unused, and enter a static IP"
	$IP = read-host 'enter an ip (10.x.x.x)'
	#customize this to your subnet mask
	$MaskBits = 16
	#update the gateway per your environment
	$Gateway = "10.x.x.x"
	#multiple DNS servers are permitted separate by comma
	$Dns = "10.x.x.x,10.x.x.x"
	$IPType = "IPv4"
	$adapter = Get-NetAdapter
#delete any existing IP settings
	If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 		$adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
	}
	If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
		$adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
	}

 # Configure the IP address and default gateway
	$adapter | New-NetIPAddress `
		-AddressFamily $IPType `
		-IPAddress $IP `
		-PrefixLength $MaskBits `
		-DefaultGateway $Gateway
# Configure the DNS client server IP addresses
	$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS
    Start-Sleep -Seconds 5

    Write-Host "testing new IP"
	#test against an external address like Google DNS here
    $connection1 = Test-Connection 8.8.8.8 -quiet
    if($connection1){
        Write-Host "ip is good connection live!"
    }
    if ( -Not $connection1 ){
        Write-Host "no connection yet...retrying in 5"
        Start-Sleep -Seconds 5
        $connection2 = Test-Connection 8.8.8.8 -quiet
        if($connection2){
            Write-Host "ip is good connection live!"
        }
        if ( -Not $connection2 ){
            Write-Host "no connection yet...retrying in 5"
            Start-Sleep -Seconds 5
            $connection3 = Test-Connection 8.8.8.8 -quiet
            if($connection3){
                Write-Host "ip is good connection live!"
            }
            if(-Not $connection3){
                write-host "something isn't right with this network setup, moving on to see if driver is needed..."
            }
        }

    }
	
}



Write-Host "testing network..."

$connection = Test-Connection 8.8.8.8 -quiet

if ( -Not $connection ){
	Write-Host "network connection is bad :("
	$connectionCheck = read-host 'are you sure the ethernet is patched? enter y or n'
	if ($connectionCheck -eq 'y'){
		Write-Host "you may just need a network driver, installing..."
		Start-Process -Wait -filePath "$PSScriptRoot\ethernet.exe" -ArgumentList "/S" -PassThru
		Start-Sleep -Seconds 2
		$connection5 = Test-Connection 8.8.8.8 -quiet
		if ( $connection5 ) {
			Write-Host "network driver installed and network is good!"
            $currentName = hostname
	        Write-Host "current computer name is $currentName"
			$hostname = read-host 'new name of this computer?'
			#customize your domain here
			$Domain = "yourDomain.priv"
			#customize your domainjoin user here
			$username = "$Domain\domainjoin"
			#customize password to your environment
			$password = "secretPasswordHere" | ConvertTo-SecureString -asPlainText -Force
			$Credential = New-Object System.Management.Automation.PSCredential($username,$password)
			if(-Not (gwmi win32_computersystem).partofdomain){
				Write-Host "sending the serial number to a text file on the desktop for inventory"
				Write-Host "copying the serial number to your clipboard to paste into inventory, enter 'y' when ready to proceed"
				Start-Sleep -Seconds 2
				$sernum = (Get-WmiObject win32_bios).Serialnumber
				Set-Clipboard -Value $sernum
				#open the inventory system automatically for the tech
				[system.Diagnostics.Process]::Start("chrome","http://otrs.eps.priv/otrs/index.pl?Action=AgentITSMConfigItem")
				$hostname >> C:\Users\technology\Desktop\serial.txt
				Get-WmiObject win32_bios | select Serialnumber >> C:\Users\technology\Desktop\serial.txt

				$readyCheck = read-host 'inventory complete and ready to proceed and join domain? enter y or n'
				if ($readyCheck -eq 'y'){
					Write-Host "no domain detected, joining domain!"
					$hname = hostname
					if($hostname -ne $hname){
						Rename-Computer $hostname
						Add-Computer -DomainName $Domain -NewName $hostname -Credential $Credential -Restart -Force
					}
					if($hostname -eq $hname){
						Write-Host "name given is the current computer name, joining domain"
						Add-Computer -DomainName $Domain -Credential $Credential -Restart -Force
					}
				}
		
	        }
	        if((gwmi win32_computersystem).partofdomain){
		        Write-Host "already on a domain!"
	        }
        }
	}
	if ($connectionCheck -eq 'n'){
		Write-Host "ensure the network is patched through, and re-run this primer!"
	}

}

if ( $connection ) {
			Write-Host "network driver installed and network is good!"
            $currentName = hostname
	        Write-Host "current computer name is $currentName"
			$hostname = read-host 'new name of this computer?'
			#customize your domain here
			$Domain = "yourDomain.priv"
			#customize your domain join account here
			$username = "$Domain\domainjoin"
			#customize the domain join password here
			$password = "secretPasswordHere" | ConvertTo-SecureString -asPlainText -Force
			$Credential = New-Object System.Management.Automation.PSCredential($username,$password)
			if(-Not (gwmi win32_computersystem).partofdomain){
				Write-Host "sending the serial number to a text file on the desktop for inventory"
				Write-Host "copying the serial number to your clipboard to paste into inventory, enter 'y' when ready to proceed"
				Start-Sleep -Seconds 2
				$sernum = (Get-WmiObject win32_bios).Serialnumber
				Set-Clipboard -Value $sernum
				#open the inventory system automatically for the tech
				[system.Diagnostics.Process]::Start("chrome","http://otrs.eps.priv/otrs/index.pl?Action=AgentITSMConfigItem")
				$hostname >> C:\Users\technology\Desktop\serial.txt
				Get-WmiObject win32_bios | select Serialnumber >> C:\Users\technology\Desktop\serial.txt

				$readyCheck = read-host 'inventory complete and ready to proceed and join domain? enter y or n'
				if ($readyCheck -eq 'y'){
					Write-Host "no domain detected, joining domain!"
					$hname = hostname
					if($hostname -ne $hname){
						Rename-Computer $hostname
						Add-Computer -DomainName $Domain -NewName $hostname -Credential $Credential -Restart -Force
					}
					if($hostname -eq $hname){
						Write-Host "name given is the current computer name, joining domain"
						Add-Computer -DomainName $Domain -Credential $Credential -Restart -Force
					}
				}
		
	        }
	        if((gwmi win32_computersystem).partofdomain){
		        Write-Host "already on a domain!"
	        }
}

Read-Host -Prompt "Press Enter to exit"
