#scan network for Windows Servers and Printers
function get-serversin{
	<#
	.Description
		Retrives hosts running Windows Server operating systems in a specified network range
	.Parameter
		Network start address.  Normally starts at .0 of the network range.
	.Example
	 Get-SrvInfo -Network 192.168.1.0
	 Scans from 192.168.1.0 to 192.168.1.254
	 #>
	
	param ($network)
	
	Begin{}
	Process{
		#declare arrays for storing information
		$servers = @()
		$printers = @()
		$vmhosts = @()
		#declare variables and initialize counters
		$previous = 0
		$last = 1
		$ip = $network
		#declare Regular Expression to match WMI OS Caption for Servers
		$regex = [Regex]"Windows\S*\sServer"
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
				#add the server object to the array for servers
				$servers += $object	
				Write-Host "Windows Server found at $ip..."
				}
				
			}
			#scan for printer response on port 9100
				if(get-PrintPort $ip){
					$printers += $ip 
					Write-Host "Printer found at $ip..."
				}
			#scan for vmware hosts on port 902
				if(get-VMPort $ip){
					$vmhosts += $ip
					Write-Host "ESX host found at $ip..."
				}
			#update the 'current' IP address
			$ip = $ip -replace "$previous$", "$last"
			#increment counters
			$last++
			$previous++
		}
		Write-Host "Scanning completed."
		#write arrays of information to files
		$printers | out-file -filepath C:\_netscanreports\printers.csv
		$servers| Export-CSV C:\_netscanreports\servers.csv -notypeinformation
		$vmhosts | out-file -filepath C:\_netscanreports\vmhosts.csv
	}
		
}	
#retrieve SQL server product keys
function Get-SQLserverKey {
    ## function to retrieve the license key of a SQL 2008 Server.
    ## by Jakob Bindslet (jakob@bindslet.dk)
    param ($targets = ".")
    $hklm = 2147483650
    $regPath = "SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\Setup"
    $regValue1 = "DigitalProductId"
    $regValue2 = "PatchLevel"
    $regValue3 = "Edition"
    Foreach ($target in $targets) {
        $productKey = $null
        $win32os = $null
        $wmi = [WMIClass]"\\$target\root\default:stdRegProv"
        $data = $wmi.GetBinaryValue($hklm,$regPath,$regValue1)
        [string]$SQLver = $wmi.GetstringValue($hklm,$regPath,$regValue2).svalue
        [string]$SQLedition = $wmi.GetstringValue($hklm,$regPath,$regValue3).svalue
        $binArray = ($data.uValue)[52..66]
        $charsArray = "B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9"
        ## decrypt base24 encoded binary data
        For ($i = 24; $i -ge 0; $i--) {
            $k = 0
            For ($j = 14; $j -ge 0; $j--) {
                $k = $k * 256 -bxor $binArray[$j]
                $binArray[$j] = [math]::truncate($k / 24)
                $k = $k % 24
         }
            $productKey = $charsArray[$k] + $productKey
            If (($i % 5 -eq 0) -and ($i -ne 0)) {
                $productKey = "-" + $productKey
            }
        }
        $win32os = Get-WmiObject Win32_OperatingSystem -computer $target
        $obj = New-Object Object
        $obj | Add-Member Noteproperty Computer -value $target
        $obj | Add-Member Noteproperty OSCaption -value $win32os.Caption
        $obj | Add-Member Noteproperty OSArch -value $win32os.OSArchitecture
        $obj | Add-Member Noteproperty SQLver -value $SQLver
        $obj | Add-Member Noteproperty SQLedition -value $SQLedition
        $obj | Add-Member Noteproperty ProductKey -value $productkey
        $obj
    }
}		
#retrieve Windows product keys
function Get-ProductKey {
     <#   
    .SYNOPSIS   
        Retrieves the product key and OS information from a local or remote system/s.
         
    .DESCRIPTION   
        Retrieves the product key and OS information from a local or remote system/s. Queries of 64bit OS from a 32bit OS will result in 
        inaccurate data being returned for the Product Key. You must query a 64bit OS from a system running a 64bit OS.
        
    .PARAMETER Computername
        Name of the local or remote system/s.
         
    .NOTES   
        Author: Boe Prox
        Version: 1.1       
            -Update of function from http://powershell.com/cs/blogs/tips/archive/2012/04/30/getting-windows-product-key.aspx
            -Added capability to query more than one system
            -Supports remote system query
            -Supports querying 64bit OSes
            -Shows OS description and Version in output object
            -Error Handling
     
    .EXAMPLE 
     Get-ProductKey -Computername Server1
     
    OSDescription                                           Computername OSVersion ProductKey                   
    -------------                                           ------------ --------- ----------                   
    Microsoft(R) Windows(R) Server 2003, Enterprise Edition Server1       5.2.3790  bcdfg-hjklm-pqrtt-vwxyy-12345     
         
        Description 
        ----------- 
        Retrieves the product key information from 'Server1'
    #>         
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeLine=$True,ValueFromPipeLineByPropertyName=$True)]
        [Alias("CN","__Server","IPAddress","Server")]
        [string[]]$Computername = $Env:Computername
    )
    Begin {   
        $map="BCDFGHJKMPQRTVWXY2346789" 
    }
    Process {
        ForEach ($Computer in $Computername) {
            Write-Verbose ("{0}: Checking network availability" -f $Computer)
            If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                Try {
                    Write-Verbose ("{0}: Retrieving WMI OS information" -f $Computer)
                    $OS = Get-WmiObject -ComputerName $Computer Win32_OperatingSystem -ErrorAction Stop                
                } Catch {
                    $OS = New-Object PSObject -Property @{
                        Caption = $_.Exception.Message
                        Version = $_.Exception.Message
                    }
                }
                Try {
                    Write-Verbose ("{0}: Attempting remote registry access" -f $Computer)
                    $remoteReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
                    If ($OS.OSArchitecture -eq '64-bit') {
                        $value = $remoteReg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DigitalProductId4')[0x34..0x42]
                    } Else {                        
                        $value = $remoteReg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('DigitalProductId')[0x34..0x42]
                    }
                    $ProductKey = ""  
                    Write-Verbose ("{0}: Translating data into product key" -f $Computer)
                    for ($i = 24; $i -ge 0; $i--) { 
                      $r = 0 
                      for ($j = 14; $j -ge 0; $j--) { 
                        $r = ($r * 256) -bxor $value[$j] 
                        $value[$j] = [math]::Floor([double]($r/24)) 
                        $r = $r % 24 
                      } 
                      $ProductKey = $map[$r] + $ProductKey 
                      if (($i % 5) -eq 0 -and $i -ne 0) { 
                        $ProductKey = "-" + $ProductKey 
                      } 
                    }
                } Catch {
                    $ProductKey = $_.Exception.Message
                }        
                $object = New-Object PSObject -Property @{
                    Computername = $Computer
                    ProductKey = $ProductKey
                    OSDescription = $os.Caption
                    OSVersion = $os.Version
                } 
                $object.pstypenames.insert(0,'ProductKey.Info')
                $object
            } Else {
                $object = New-Object PSObject -Property @{
                    Computername = $Computer
                    ProductKey = 'Unreachable'
                    OSDescription = 'Unreachable'
                    OSVersion = 'Unreachable'
                }  
                $object.pstypenames.insert(0,'ProductKey.Info')
                $object                           
            }
        }
    }
} 
#retrieve network share information
function get-Shares {
	param ($computer)
	Begin{}
	Process{
		$colItems = get-wmiobject -class "Win32_Share" -namespace "root\CIMV2" -computername $computer
		$shares = @()
		foreach ($objItem in $colItems) { 
			$object = New-Object PSObject -Property @{
			Caption = $objItem.Caption 
			Description = $objItem.Description 
			Name = $objItem.Name 
			Path = $objItem.Path 
			Status = $objItem.Status 
			ShareType = $objItem.Type 
			
			}
			$shares += $object
		}
		$shares
	}

}
#check for responses on port 9100 (printers)
function get-PrintPort{
    Param([string]$srv="localhost",$port=9100,$timeout=300)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
    if(!$wait)
    {
        $tcpclient.Close()
        Return $false
    }
    else
    {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        Return $true
        $tcpclient.Close()
    }
}
#scan VMWare ESX heartbeat port
function get-VMPort{
    Param([string]$srv="localhost",$port=902,$timeout=300)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
    if(!$wait)
    {
        $tcpclient.Close()
        Return $false
    }
    else
    {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        Return $true
        $tcpclient.Close()
    }
}
#main function that is passed network to scan
#calls other functions to execute the scan
function get-SvrInfo{
	param ($network)
	
	Begin{}
	
	Process{
		Get-ServersIn $network
		$serverIPs = @()
		#import the IPs listed in the servers.csv file from 'get-ServersIn' function
		$serverIPs = Import-CSV C:\_netscanreports\servers.csv
		#declare object arrays for servers and keys
		$SQLsrvs = [Object]@()
		$Serverkeys = [Object]@()
		$i = 0
		#loop through list of server IP addresses
		foreach ($ipaddr in $serverIPs){
			$ipaddr = $serverIPs[$i].IPaddr
			#get the product keys for Windows
			Try{
				Write-host "Finding product key on host $ipaddr..."
				
				$Serverkeys += Get-ProductKey $ipaddr
				
			}
			Catch{
			}
			#get the SQL server product keys
			Try{
				Write-host "Finding SQL key on host $ipaddr..."
				$SQLsrvs += Get-SQLserverKey $ipaddr
				
			}
			Catch{
			}
			#Get CPU, RAM, and Share information as well as services on the machine
			Try{
				Write-host "Finding Services and information on host $ipaddr..."
				$svrname = $serverIPs[$i].Name
				get-wmiobject win32_processor -computername $ipaddr | out-file -filepath C:\_netscanreports\serverdetails\$svrname.txt -append -noclobber
				$RAM = Get-WMIObject -class Win32_PhysicalMemory -ComputerName $ipaddr | Measure-Object -Property capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)}
				$strRAM = "Total RAM installed: $RAM GB"
				$strRAM | out-file -filepath C:\_netscanreports\serverdetails\$svrname.txt -append -noclobber
				$services = get-service -computername $ipaddr | sort-object status 
				$services | out-file -filepath C:\_netscanreports\serverdetails\$svrname.txt -append -noclobber 
				$shares = get-Shares $ipaddr
				$shares | out-file -filepath C:\_netscanreports\serverdetails\$svrname.txt -append -noclobber
			}
			Catch{
			}
			
			#increment counter
			$i += 1		
		}
		#write arrays to files
		$SQLsrvs| Export-CSV C:\_netscanreports\SQLservers.csv -notypeinformation
		$Serverkeys| Export-CSV C:\_netscanreports\serverKeys.csv -notypeinformation
	
		Write-Host "Reports available on the C:"
	
	}
}
#request user input, create _netscanreports directory and start scan
$net = Read-Host "Enter a network in the form of 192.168.1.0:"
New-Item -itemtype directory -path c:\_netscanreports
New-Item -itemtype directory -path c:\_netscanreports\serverdetails
get-svrinfo $net