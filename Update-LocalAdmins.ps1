#___________Update-LocalAdmins PS Script_____________________
#Function to add or remove a user to the local administrator
#group on a remote machine.
#
#Use:	from powershell <path>.\update-localadmins.ps1
#At the prompt enter the computer name or IP address
#Enter the username with no domain to edit, for example:
#jsmith
#Enter the domain name the user is a part of, for example:
#mydomain.net
#Select whether you want to add or remove rights by entering
#an 'a' or 'r'.
#Once the script executes it should list the current local
#Administrators and the updated local admins on the remote machine.
#___________________________________________________________
function update-localadmins{
	param(
		[string[]]$strComputer,
		[string[]]$username,
		[string[]]$option,
		[string[]]$dm
	)
	#Write-host $option
	$domain = $dm
	$computer = [ADSI]("WinNT://" + $strComputer + ",computer")
	$computer.name

	$Group = $computer.psbase.children.find("administrators")
	$Group.name


	
	Write-output "::Current Admins::"
	$members= $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
	$members
	Write-Output "::::::::::::::::::"

	
	if ($option -eq "a")
	{
		$Group.Add("WinNT://" + $domain + "/" + $username)
		
	}

	elseif ($option -eq "r")
	{
	$Group.Remove("WinNT://" + $domain + "/" + $username)
	}
	write-output "::Updated Admins::"
	$members= $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
	$members
	write-output "::::::::::::::::::"
}

$cn = Read-Host "Enter the computer name or IP: "
$un = Read-Host "Enter the username to modify (no domain): "
$dm = Read-Host "Enter the domain name (machine name = localhost): "
$opt = Read-Host "Add (a) or Remove (r) admin rights?: "

update-localadmins -strComputer $cn -username $un -option $opt -dm $dm