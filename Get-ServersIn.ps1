function get-serversin{
	<#
	.Description
		Retrives hosts running Windows Server operating systems in a specified network range
	.Parameter
		Network start address.  Normally starts at .0 of the network range.
	.Example
	 Get-ServersIn -Network 192.168.1.0
	 Scans from 192.168.1.0 to 192.168.1.254
	 #>
	
	param ($network)
	
	Begin{}
	Process{
		$previous = 0
		$last = 1
		$ip = $network
		$regex = [Regex]"Windows\S*\sServer"
		Write-Host "Scanning network $ip..."
		while ($previous -lt 255){
			
			Write-Verbose ("{0}: Checking network availability" -f $ip)
            
			If (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
				Try{
				    $OS = Get-WmiObject -ComputerName $ip Win32_OperatingSystem -ErrorAction Stop       
                } Catch {
                    $OS = New-Object PSObject -Property @{
                        Caption = $_.Exception.Message
                        Version = $_.Exception.Message
                    }
                }
				
				if ($OS.caption -match $regex){
					$object = New-Object PSObject -Property @{
					IPaddr = $ip
					Name = $OS.__SERVER
					OSVersion = $os.caption
					}
				$object
						
				}				
			}			
			$ip = $ip -replace "$previous$", "$last"
			$last++
			$previous++
		}
		Write-Host "Scanning completed."
	}
		
}	
			