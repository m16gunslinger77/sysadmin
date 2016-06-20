function get-pcsin{
	<#
	.Description
		Retrives hosts running Windows operating systems in a specified network range
	.Parameter
		Network start address.  Normally starts at .0 of the network range.
	.Example
	 Get-pcsIn -Network 192.168.1.0
	 Scans from 192.168.1.0 to 192.168.1.254
	 #>
	
	param ($network)
	
	Begin{}
	Process{
		#declare arrays for storing information
		$pcs = @()
		$printers = @()
		$vmhosts = @()
		#declare variables and initialize counters
		$previous = 0
		$last = 1
		$ip = $network
		#declare Regular Expression to match WMI OS Caption for pcs
		$regex = [Regex]"Windows*"
		Write-Host "Scanning network $ip..."
		#loop through IP addresses in network up to .254
		while ($previous -lt 255){
			
			Write-Verbose ("{0}: Checking network availability" -f $ip)
            #show progress bar and current IP address for progress of network scan
			Write-Progress -Activity "Scanning network" -status "Scanning $ip" -percentComplete ($last/255*100)
			
			#if a response is received on the IP retrieve WMI information
			If (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
				Try{
					#get the operating system info from WMI
				    $OS = Get-WmiObject -ComputerName $ip Win32_OperatingSystem -ErrorAction Stop       
                } Catch {
                    $OS = New-Object PSObject -Property @{
                        Caption = $_.Exception.Message
                        Version = $_.Exception.Message
                    }
                }
				#check to see if the OS is Windows Server
				if ($OS.caption -match $regex){
					#create a server object containing properites of the host
					$object = New-Object PSObject -Property @{
					IPaddr = $ip
					Name = $OS.__SERVER
					OSVersion = $os.caption
					}
				#add the server object to the array for computers
				$pcs += $object	
				Write-Host "Windows machine found at $ip..."
				}
				
			}
			#update the 'current' IP address
			$ip = $ip -replace "$previous$", "$last"
			#increment counters
			$last++
			$previous++
		}
		Write-Host "Scanning completed."
		#write arrays of information to files
		
		$pcs| Export-CSV C:\_netscanreports\pcs.csv -notypeinformation
		
	}
		
}	
$net = Read-Host "Enter a network in the form of 192.168.1.0:"
get-pcsin $net