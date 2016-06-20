#___________Get-Printers PS Script_____________________
#Function to list the local printers on a remote machine
#
#Use:	from powershell <path>.\get-printers.ps1
#At the prompt enter the computer name or IP address
#
#Once the script executes it should list the current local
#printers on the remote machine.
#________________________________________________________
$cn = Read-Host "Enter a computername or IP: "
get-WMIObject -class win32_printer -cn $cn | select Name,DriverName,PortName | ft -auto