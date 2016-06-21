#######################################
# VMWare Snapshot report generator    #
# version 0.3                         #
# written by Mike Naylor              #
# 1/20/2015                           #
#######################################

add-pssnapin VMware.VimAutomation.Core
Connect-VIServer vCenter

$date = Get-Date -format M

$break1 = "________________________________________________"
$break2 = "################################################"
$path = $env:USERPROFILE + "\desktop\VMWare Snapshot Report " + $date + ".txt"
$dateFull = Get-Date
$header = "VMWare Snapshot Report for " + $datefull

$header | Out-File -FilePath $path
$break1 | Out-File -noclobber -append -filepath $path
$break1 | Out-File -noclobber -append -filepath $path

$servers = "SERVERNAMES HERE"

$servers | ForEach-Object{

    $snap = Get-VM -name $_ | Get-Snapshot | format-list VM,Name,Description,ID,Created,SizeMB

    if([string]::IsNullOrEmpty($snap) ){
        #Write-Host $_ "does not have a snapshot"
    }
    Else{
        $text = $_ + " has at least one snapshot present."
        
        $text |Out-File -noclobber -append -filepath $path  
        $snap | Out-File -noclobber -append -filepath $path
        $break2 | Out-File -noclobber -append -filepath $path
        $break2 | Out-File -noclobber -append -filepath $path
        
    }

    
}

Invoke-Item $path
