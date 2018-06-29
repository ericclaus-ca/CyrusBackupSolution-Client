<#
    .SYNOPSIS
        Backs up EveryonePrint's configuration.     

    .NOTES
        Author: Eric Claus
        Last modified: 2/22/2018
#>

$printServer = "print1"

$everyonePrintRootDir = "\\$printServer\C`$\Program Files (x86)\EveryonePrint"

$backupName = "EOP-$printServer-Backup_$(Get-Date -Format M-d-yyyy)"

$backupDirectory = "\\nas1\d`$\NASShare\dr\EveryonePrint\$backupName"

Set-Service -ComputerName "$printServer" -Name "EOPData" -Status "Stopped"
Set-Service -ComputerName "$printServer" -Name "EveryonePrint Print Service" -Status "Stopped"
Set-Service -ComputerName "$printServer" -Name "EOPWeb" -Status "Stopped"

Copy-Item -Recurse "$everyonePrintRootDir\data" -Destination "$backupDirectory\data"
Copy-Item -Recurse "$everyonePrintRootDir\etc" -Destination "$backupDirectory\etc"
Copy-Item "$everyonePrintRootDir\eop.xml" -Destination $backupDirectory
Copy-Item "$everyonePrintRootDir\printers.xml" -Destination $backupDirectory

Set-Service -ComputerName "$printServer" -Name "EOPData" -Status "Running"
Set-Service -ComputerName "$printServer" -Name "EveryonePrint Print Service" -Status "Running"
Set-Service -ComputerName "$printServer" -Name "EOPWeb" -Status "Running"