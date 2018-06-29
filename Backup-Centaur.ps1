function Backup-Centaur {
    <#
        .SYNOPSIS
            Backs up the Centaur Door Access System's databases.     
    
        .DESCRIPTION
            This script requires that scheduled database backup jobs be created in Centaur. 
            For instructions, see http://doku/doku.php?id=dr:centaur_backup
    
        .NOTES
            Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
            Last modified: 05/15/2018
    #>

    $date = (Get-Date).ToString("MM-dd-yyyy")

    $backupFileName = "Centaur-$date.7z"

    $backupDestination = "\\nas1\d$\NASShare\dr\Centaur"

    $centaurServer = "172.17.5.140"

    $backupSourcePath = "\\$centaurServer\C$\Backup"

    $backupFileExtension = "BAK"

    $tempFile = "$backupSourcePath\$backupFileName"

    # Get the password to encrypt the backup with
    . "$PSScriptRoot\Other\Get-SecurePassword.ps1"
    $backupEncryptionKey = (Get-SecurePassword -PwdFile "$PSScriptRoot\Other\1120701825").Password
    
    #Copy-Item -Recurse $backupSourcePath -Filter $backupFileExtension -Destination $backupDestination

    Get-ChildItem $backupSourcePath -Recurse -File | 
        Where-Object {$_.Extension -match $backupFileExtension} | 
        % {$_.FullName} |
        Compress-7Zip -Format SevenZip -ArchiveFileName $tempFile -SecurePassword $backupEncryptionKey

    Move-Item $tempFile -Destination $backupDestination
}