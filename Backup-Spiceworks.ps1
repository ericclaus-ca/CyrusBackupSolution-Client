function Backup-Spiceworks {
    <#
        .SYNOPSIS
            Backs up Spicework's data and database.     

        .NOTES
            Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
            Last modified: 05/15/2018
    #>
    #Requires –Modules 7Zip4PowerShell
    #Uncomment line below to install the module
    #Install-Module -Name 7Zip4PowerShell

    $server = "spiceworks1"

    echo "Backing up $server..."

    $spiceworksRootDir = "\\$server\C`$\Program Files (x86)\Spiceworks"

    $backupName = "SW-$server-Backup_$(Get-Date -Format M-d-yyyy)"

    $tempBackupLocation = "\\$server\C`$\Users\RobertLee\Desktop"
    
    $tempBackupFolder = "$tempBackupLocation\$backupName"
    mkdir $tempBackupFolder

    $backupDirectory = "\\nas1\d`$\NASShare\dr\spiceworks"

    $BackupFile = "$tempBackupLocation\$backupName.7z"

    # Get the password to encrypt the backup with
    . "$PSScriptRoot\Other\Get-SecurePassword.ps1"
    $backupEncryptionKey = (Get-SecurePassword -PwdFile "$PSScriptRoot\Other\1859189471").Password

    $itemsToBackup = @(
        "$spiceworksRootDir\data",
        "$spiceworksRootDir\db"
    )
 
    foreach ($item in $itemsToBackup) {
        Copy-Item -Recurse $item -Destination $tempBackupFolder
    }

    Get-ChildItem $tempBackupFolder -Recurse -File | % {$_.FullName} |
        Compress-7Zip -Format SevenZip -ArchiveFileName $BackupFile -SecurePassword $backupEncryptionKey

    Move-Item $BackupFile -Destination $backupDirectory
    
    Remove-Item $tempBackupFolder -Recurse -Force

    echo "$server backed up as $tempBackupFile and completed."
}