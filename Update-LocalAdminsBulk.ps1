function Update-LocalAdminsBULK {
<#
    .Description
    Reads a .csv file with computer names and user names.
    Removes the user from the local admin group on the machine.

    .Requirements
    CSV columns: 1=Computer 2=User
    Usernames without domain ie: jadams NOT test.net\jadams
    Computer names must resolve via DNS

    .Parameters
    Path to the .csv file
    domain name

    .Example
    Update-LocalAdminsBulk -path C:\users.csv -domain test.net


    .Author
    Mike Naylor
    7/2014
    #>

[cmdletbinding()]
Param(
    [string[]]$path,
    [string[]]$domain
    )

Begin{}
Process{
    
    $list = import-csv -path $path | Foreach-Object {
        $strcomputer = $_.Computer
        $username = $_.user
        #Write-output "Trying CPU-User combination"
        #Write-output $strcomputer
        Try{
			$computer = [ADSI]("WinNT://" + $strComputer + ",computer")
			$computer.name

			$Group = $computer.psbase.children.find("administrators")
			$Group.name
			#output current administrators
			#Write-host "@@@@@@@@@@@@@@@@@@"
			#Write-host "::Current Admins::"
			#ListAdministrators
			#Write-host "::::::::::::::::::"
			#remove the user from the Local Admins group
			$Group.Remove("WinNT://" + $domain + "/" + $username)
			#output updated Local Admins members
			write-host "Machine: " + $strcomputer + " User: " + $username
			write-host "::Updated Local Admins List::"
			ListAdministrators
			write-host "::::::::::::::::::"
			write-host "__________________"
		}
		Catch{
			write-host "######ERROR######"
			write-host "Error trying computer :" + $strcomputer + " and user: " + $username
			write-host "#################"
		}
		Finally{
			write-host "__________________"
		}
    }
    


}

}

function ListAdministrators{
    $members= $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}
    foreach ($member in $members){
        write-host "--", $member
    }
}

#Prompt user for path to .csv file
$upath = Read-Host "Enter the path to the machine-user list .csv file: "
$udomain = Read-Host "Enter the domain name ie(test.net): "
Update-LocalAdminsBulk -path $upath -domain $udomain
#Pause before exiting
write-host "Press any key to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")