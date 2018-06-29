function Backup-Xibo {
    <#
        .SYNOPSIS
            Backs up Xibo.     
    
        .DESCRIPTION
            Xibo on Docker automatically backs up the Xibo database. This script copys and encrypts
            those backups to the NAS server. For related Xibo documentation, see.
    
        .NOTES
            Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
            Last modified: 05/31/2018

        .LINKS
            
    #>

    $date = (Get-Date).ToString("MM-dd-yyyy")

    $backupFileName = "Xibo-$date.7z"

    $backupDestination = "\\nas1\d$\NASShare\dr\Xibo"

    $xiboServer = "172.17.5.31"

    $backupSourcePath = "\\xibo\d$\xibo\xibo-docker-1.8.9"

    $tempFile = "$backupSourcePath\$backupFileName"

    # Get the password to encrypt the backup with
    . "$PSScriptRoot\Other\Get-SecurePassword.ps1"
    $backupEncryptionKey = (Get-SecurePassword -PwdFile "$PSScriptRoot\Other\827053801").Password

    # Files/folders to exclude from being backed up, regular expression
    $exclude = "\\shared\\cms\\library\\cache\\"

    Get-ChildItem $backupSourcePath -Recurse -File | 
        Where-Object {$_.FullName -notmatch $exclude} |
        % {$_.FullName} |
        Compress-7Zip -Format SevenZip -ArchiveFileName $tempFile -SecurePassword $backupEncryptionKey

    Move-Item $tempFile -Destination $backupDestination
}