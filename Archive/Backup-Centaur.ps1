<#
    .SYNOPSIS
        Backs up Centaur's database.     

    .DESCRIPTION
        This script requires that scheduled database backup jobs be created in Centaur. 
        For instructions, see http://doku/doku.php?id=dr:centaur_backup

    .NOTES
        Author: Eric Claus
        Last modified: 03/02/2018
#>

$date = (Get-Date).ToString("MM-dd-yyyy")

$backupDestination = "\\nas1\d$\NASShare\dr\Centaur\$date\"
mkdir $backupDestination

$centaurServer = "172.17.5.140"

$backupSourcePath = "\\$centaurServer\C$\Backup\*"

$backupFileExtension = "*.BAK"

Copy-Item $backupSourcePath -Filter $backupFileExtension -Destination $backupDestination