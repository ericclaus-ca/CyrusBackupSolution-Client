function Backup-EOP {
    <#
        .SYNOPSIS
            Backs up EveryonePrint's configuration.     

        .NOTES
            Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
            Last modified: 05/15/2018
    #>
    #Requires –Modules 7Zip4PowerShell
    #Uncomment line below to install the module
    #Install-Module -Name 7Zip4PowerShell

    $printServer = "print1"

    $everyonePrintRootDir = "\\$printServer\C`$\Program Files (x86)\EveryonePrint"

    $backupName = "EOP-$printServer-Backup_$(Get-Date -Format M-d-yyyy)"

    $tempBackupFolder = "$everyonePrintRootDir\$backupName"
    mkdir $tempBackupFolder

    $backupDirectory = "\\nas1\d`$\NASShare\dr\EveryonePrint"

    $tempBackupFile = "$everyonePrintRootDir\$backupName.7z"

    # Get the password to encrypt the backup with
    . "$PSScriptRoot\Other\Get-SecurePassword.ps1"
    $backupEncryptionKey = (Get-SecurePassword -PwdFile "$PSScriptRoot\Other\1592466387").Password

    Set-Service -ComputerName "$printServer" -Name "EOPData" -Status "Stopped"
    Set-Service -ComputerName "$printServer" -Name "EveryonePrint Print Service" -Status "Stopped"
    Set-Service -ComputerName "$printServer" -Name "EOPWeb" -Status "Stopped"

    $itemsToBackup = @(
        "$everyonePrintRootDir\data",
        "$everyonePrintRootDir\etc",
        "$everyonePrintRootDir\eop.xml",
        "$everyonePrintRootDir\printers.xml"
    )
 
    foreach ($item in $itemsToBackup) {
        Copy-Item -Recurse $item -Destination $tempBackupFolder
    }

    Get-ChildItem $tempBackupFolder -Recurse -File | % {$_.FullName} |
        Compress-7Zip -Format SevenZip -ArchiveFileName $tempBackupFile -SecurePassword $backupEncryptionKey

    Set-Service -ComputerName "$printServer" -Name "EOPData" -Status "Running"
    Set-Service -ComputerName "$printServer" -Name "EveryonePrint Print Service" -Status "Running"
    Set-Service -ComputerName "$printServer" -Name "EOPWeb" -Status "Running"

    Move-Item $tempBackupFile -Destination $backupDirectory
    Remove-Item $tempBackupFolder
}