<#
.SYNOPSIS
    Automatically the MySQL Database of the Student Application Site.

.DESCRIPTION
    This script performs a full backup of the "ca_applications" table of the 
    MySQL database used for the Student Application Site.

Requirements: 
  * The Posh-SSH module must be installed (Install-Module -Name Posh-SSH).
  * Get-SecurePassword.ps1 script must be dot sourced.
  * A secure password file containing the password for the MySQL database. To generate this file, 
      you can use the custom function: New-SecurePassFile.You can run it manually once to save the 
      secure password and the username (this must be done on the same computer and by the same user 
      account which will be running this backup script).
  * A secure password file containing the password for the zip file encryption for the SQL backup.
  * The 7Zip4PowerShell module must be installed on the Sync server where the application site resides.

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last Modified: 12/14/2018

.COMPONENT
    Get-SecurePassword, 7Zip4PowerShell
#>

function Backup-StudentApplicationSiteDB {
    #Requires -Modules 7Zip4PowerShell

    # Include the Compare-Files, Get-SecurePassword and Start/Stop-SolarwindsTftpServer functions
    $myFunctions = @(
        "$PSScriptRoot\Other\Get-SecurePassword.ps1"
        )
    $myFunctions | ForEach-Object {
        If (Test-Path $_) {. $_}
        Else {throw "Error: At least one necessary function was not found."; Exit 1}
    }

    $today = (Get-Date).ToString("MM-dd-yyyy_HH-mm")

    ########## Begin Error Handling ##########

    # Thanks to Keith Hill for this trap idea.
    # https://stackoverflow.com/questions/14246512/send-an-email-if-a-powershell-script-gets-any-errors-at-all-and-terminate-the-sc
    function ErrorHandler {
        Write-Output $_
        # Send an email to Spiceworks, creating a ticket, if there are any errors.
        # Thanks to https://www.pdq.com/blog/powershell-send-mailmessage-gmail/ for the code below. 
        $From = "fortigate-log@collegedaleacademy.com"
        $To = "help@collegedaleacademy.com"
        $Subject = "Student Application Site DB Backup Error"
        $Body = "There has been an error with the automatic backup of the Student Application Site's DB. See the attached log file for details. -- $_"
        $SMTPServer = "aspmx.l.google.com"
        $SMTPPort = "25"
        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl
    }
    # If any terminating error occurs, invoke the ErrorHandler function and stop the script
    trap {ErrorHandler; Exit 1}
    # Treat all errors as terminating, useful for the trap statement above
    $ErrorActionPreference = "Stop"

    ########## End Error Handling ##########
    
    # Name of the Sync server where the Student Application site resides
    $syncServer = "Sync2"

    ########## Begin Credential Management ##########
    
    # Username of the account used for the MySQL database, and the secure password file with it's password
    $userName = "root"
    $pwdFile = "$PSScriptRoot\Other\1198809618"
    
    # Get the secure password and convert to plain text
    $pass = (Get-SecurePassword $pwdFile).GetNetworkCredential().Password
    
    # Encryption key for the zip encryption
    $encryptionPwdFile = "$PSScriptRoot\Other\2103043740"
    $backupEncryptionKey = (Get-SecurePassword $encryptionPwdFile).GetNetworkCredential().Password
    
    ########## End Credential Management ##########

    # The target backup directory
    $backupDir = "\\nas1\d$\NASShare\dr\Student Application Site\DB"
    New-Item $backupDir -ItemType Directory -Force | Out-Null

    # MySQL bin directory where mysqldump.exe is located and is to be ran from
    $mySqlBinDir = "C:\xampp\mysql\bin"
    
    # Log file and temp backup file (.sql file) are to be stored
    $logFile = "$mySqlBinDir\_DbBkLog_$today.log"
    $backupFileTemp = "$mySqlBinDir\_ca-applications_$today.sql"
    
    # Permanent Backup file name (.7z)
    $backupFileEncrypted = "$mySqlBinDir\_ca-applications_$today.7z"

    # Command to cd into the MySQL Bin Directory
    $cdCommand = "Set-Location $mySqlBinDir"

    # Backup (dump) command
    $mysqldumpCommand = "$mySqlBinDir\mysqldump.exe --user=$userName --password=$pass --log-error=$logFile --result-file=$backupFileTemp --databases 'ca_applications'"
     
    # Command to compress and encrypt the backup file
    $7zipCommand = "Compress-7Zip -Format SevenZip -Path $backupFileTemp -ArchiveFileName $backupFileEncrypted -Password $backupEncryptionKey"

    # Command to delete the temp .sql file
    $deleteTempFileCommand = "Remove-Item $backupFileTemp -Force"

    # Run the commands on the Sync server
    Invoke-Command -ComputerName $syncServer -ScriptBlock { 
        Invoke-Expression $args[0];
        Invoke-Expression $args[1];
        Invoke-Expression $args[2];
        Invoke-Expression $args[3]
    } -ArgumentList ($cdCommand,$mysqldumpCommand, $7zipCommand, $deleteTempFileCommand)

    # A quick and dirty way to correct the path to the backup file to support remote access
    # If the local path the backup file is stored at changes drives (e.g. to D:\) this
    # line must be changed as well.
    $remoteBackupFileEnctyptedPath = $backupFileEncrypted.Replace("C:","C$")
    Move-Item \\$syncServer\$remoteBackupFileEnctyptedPath $backupDir
}