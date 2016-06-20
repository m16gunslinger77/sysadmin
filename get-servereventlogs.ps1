Function get-ServerEventLogs{

<#
    .Description
    Retrieve Windows event log information from a list of servers

#>

[cmdletbinding()]
Param(
    [string[]]$path
    )

Begin{}
Process{

    $list = import-csv -path $path | Foreach-Object {
        $strcomputer = $_.SERVERS
        write-host $strcomputer
         Try{
            $wpath = "C:\_ServerEvents\" + $strcomputer + ".csv"
            get-eventlog system -cn $strcomputer | Where-Object {$_.EntryType -ne "Information"} | Export-CSV $wpath -notypeinformation
                  
            


         }
         Catch{}
        }
    }

}

$upath = Read-Host "Enter the path to the machine-user list .csv file: "
get-ServerEventLogs -path $upath