<#
.SYNOPSIS
    This is a Powershell script to automatically backup Dokuwiki.

.DESCRIPTION
    This script can be used in conjunction with Posh-SSH and Task Scheduler to automate the
    backup of Dokuwiki. If needed, it can support backing up multiple Dokuwiki instances.

Requirements: 
  * The Posh-SSH module must be installed (Install-Module -Name Posh-SSH). 
  * A secure password file containing the Dokuwiki local admin password as a secure string.
      You can use New-SecurePassFile to generate this file. You can run it manually once to 
      save the secure password (this must be done on the same computer and by the same user 
      account which will be running this backup script).
  * The custom Get-SecurePassword function.

.INPUTS
    This script does not accept any inputs.

.OUTPUTS
    This script does not create any output.

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last Modified: 05/04/2018

.LINK
    http://doku/doku.php?id=dr:dokuwiki_backup_and_restore

.COMPONENT
    Posh-SSH, Get-SecurePassword.ps1
#>

function Backup-Dokuwiki {
    #Requires -Modules Posh-SSH

    # Include the Get-SecurePassword and Start/Stop-SolarwindsTftpServer functions
    $myFunctions = @(
        "$PSScriptRoot\Other\Get-SecurePassword.ps1"
        )
    $myFunctions | ForEach-Object {
        If (Test-Path $_) {. $_}
        Else {throw "Error: At least one necessary function was not found."}
    }

    #$today = (Get-Date).ToString("MM-dd-yyyy_HH-mm")

    ##### Begin Error Handling #####

    # Thanks to Keith Hill for this trap idea.
    # https://stackoverflow.com/questions/14246512/send-an-email-if-a-powershell-script-gets-any-errors-at-all-and-terminate-the-sc
    function ErrorHandler {
        echo $_
        # Send an email if there are any errors.
        # Thanks to https://www.pdq.com/blog/powershell-send-mailmessage-gmail/ for the code below. 
        $From = "fortigate-log@collegedaleacademy.com"
        $To = "help@collegedaleacademy.com"
        $Subject = "Dokuwiki Backup Error"
        $Body = "There has been an error with the automatic backup of Dokuwiki. See the attached log file for details. -- $_"
        $SMTPServer = "aspmx.l.google.com"
        $SMTPPort = "25"
        #Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl
    }
    # If any terminating error occurs, invoke the ErrorHandler function and stop the script
    trap {ErrorHandler}
    # Treat all errors as terminating, useful for the trap statement above
    $ErrorActionPreference = "Stop"

    ##### End Error Handling #####

    ##### Begin Credential Management #####

    # Username local Ubuntu user
    $userName = "doku"
    # The secure password file with it's password
    # CHANGE THIS WHENEVER THE SCRIPT IS RUN ON A NEW COMPUTER OR BY A NEW USER
    $pwdFile = "$PSScriptRoot\Other\1452097632"
    # Create a PSCredential object with the username and password above
    $credentials = Get-SecurePassword -PwdFile $pwdFile -userName $userName

    ##### End Credential Management #####

    # Create an array of the IP addressess of the desired Dokuwiki server(s)
    $ipAddresses = @(
        [ipaddress]"172.17.5.78"
        )   

    # Loop through the servers
    foreach ($ipAddress in $ipAddresses) {

        echo "Backing up: $ipAddress..."

        # The Dokuwiki data directory
        $dokuDataDir = "/var/www/dokuwiki"

        # Backup file name
        $fileName = "`$(date +'%m-%d-%y').tar.gz"

        # Path to network share mouted on the Ubuntu Server
        $backupDir = "/media/backup"

        # The commands to send to the host
        # First, enter sudo
        $sudoCommand1 = "sudo -i"
        $sudoCommand2 = $credentials.GetNetworkCredential().Password
        # First, compress the Dokuwiki data directory
        $backupCommand1 = "tar -zcf $fileName $dokuDataDir"
        # Second, move the backup file to the Dokuwiki backup network share
        $backupCommand2 = "mv  $fileName $backupDir"

        # Create a new SSH session and shell stream (necessary for sudo to work properly)
        $session = New-SSHSession -ComputerName $ipAddress -Credential $credentials -AcceptKey:$True
        $shellStream = New-SSHShellStream -SSHSession $session
    
        # Send the backup commands over SSH
        $shellStream.WriteLine($sudoCommand1)
        Sleep 5
        $shellStream.WriteLine($sudoCommand2)
        Sleep 5
        $shellStream.WriteLine($backupCommand1)
        Sleep 30
        $shellStream.WriteLine($backupCommand2)
        Sleep 30

        # Close the SSH session
        $shellStream.WriteLine("logout")
        Remove-SSHSession -SSHSession $session
    
        echo "$ipAddress backed up on $today." #| Out-File -Append $log
    
        echo "Backup of $ipAddress is complete."
    }
}