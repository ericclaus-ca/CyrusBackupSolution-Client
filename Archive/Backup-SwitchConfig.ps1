<#
.SYNOPSIS
    Automatically backup HP Procurve Switch config files.

.DESCRIPTION
    This script loops through a list of switches, connects to them via SSH, and
    backs up their configurations. It compares the new config backup to the 
    previous one, and only keeps the new backup file if a change has been made 
    to the config since the last backup.

Requirements: 
  * The Posh-SSH module must be installed (Install-Module -Name Posh-SSH).
  * Compare-Files.ps1, Get-SecurePassword.ps1, and StartStop-SolarwindsTftpServer.ps1 scripts must be dot sourced.
  * Solarwinds TFTP Server must be installed: http://www.solarwinds.com/free-tools/free-tftp-server
  * A firewall rule named "TFTP" to allow UDP port 69 inbound (it can be disabled). 
  * A secure password file containing the switches' password as a secure string. To generate this file, 
      you can use the custom function: New-SecurePassFile.You can run it manually once to save the 
      secure password (this must be done on the same computer and by the same user account which will 
      be running the Fortigate backup script).

.INPUTS
    This script does not accept any inputs.

.OUTPUTS
    This script does not create any output.

.NOTES
    Author: Eric Claus
    Last Modified: 02/22/2018

    Thanks to the following people (see Link section):
    Carlos Perez (aka. darkoperator) for the Posh-SSH module and documentation.
    Sebastian Feldmann for his blog post about a similar script, which this is based on. 

.LINK
    http://doku/doku.php?id=other:compare-files
    http://doku/doku.php?id=dr:switch_config_backup
    https://github.com/darkoperator/Posh-SSH
    http://blog.feldmann.io/powershell/backup-hp-procurve-switches-via-ssh-tftp-and-powershell/

.COMPONENT
    Posh-SSH, Compare-Files, Get-SecurePassword, StartStop-SolarwindsTftpServer.ps1
#>

#Requires -Modules Posh-SSH

# Include the Compare-Files, Get-SecurePassword and Start/Stop-SolarwindsTftpServer functions
$myFunctions = @(
    "$PSScriptRoot\Compare-Files.ps1",
    "$PSScriptRoot\Get-SecurePassword.ps1",
    "$PSScriptRoot\StartStop-SolarwindsTftpServer.ps1"
    )
$myFunctions | ForEach-Object {
    If (Test-Path $_) {. $_}
    Else {throw "Error: At least one necessary function was not found."; Exit 1}
}

# Start a transcript of the Powershell session for logging
$scriptName = $MyInvocation.MyCommand.Name
$transcript = "$PSScriptRoot\$scriptName.transcript"
Start-Transcript -Path $transcript

$today = (Get-Date).ToString("MM-dd-yyyy_HH-mm")

########## Begin Error Handling ##########

# Thanks to Keith Hill for this trap idea.
# https://stackoverflow.com/questions/14246512/send-an-email-if-a-powershell-script-gets-any-errors-at-all-and-terminate-the-sc
function ErrorHandler {
    echo $_
    Stop-TftpServer
    Stop-Transcript
    # Send an email to Spiceworks, creating a ticket, if there are any errors.
    # Thanks to https://www.pdq.com/blog/powershell-send-mailmessage-gmail/ for the code below. 
    $From = "fortigate-log@collegedaleacademy.com"
    $To = "help@collegedaleacademy.com"
    $Attachment = $transcript
    $Subject = "Switch Config Backup Error"
    $Body = "There has been an error with the automatic backup of the switches's configurations. See the attached log file for details. -- $_"
    $SMTPServer = "aspmx.l.google.com"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Attachments $Attachment
}
# If any terminating error occurs, invoke the ErrorHandler function and stop the script
trap {ErrorHandler; Exit 1}
# Treat all errors as terminating, useful for the trap statement above
$ErrorActionPreference = "Stop"

########## End Error Handling ##########

# Username of the admin account on the switches, and the secure password file with it's password
$userName = "admin"
$pwdFile = "$PSScriptRoot\1451877995"
# Create a PSCredential object with the username and password above
$credentials = Get-SecurePassword -PwdFile $pwdFile -userName $userName

# Use Posh-SSH to SSH into the switches and backup their configs
function SSH-BackupSwitch {
    param(
        [string]$switch,
        [string]$backupCommand,
        [System.Management.Automation.PSCredential]$credentials
    )

    # Create a new SSH session to the switch
    $session = New-SSHSession -ComputerName $switch -Credential $credentials -AcceptKey:$True
    
    # Straight SSH sessions will not work with HP's switches. They require an SSH Shell Stream.
    $shellStream = New-SSHShellStream -SSHSession $session

    # Send a space to get past the "Press any key to continue" screen (could be any key)
    $shellStream.WriteLine(" ")

    # First, save the current running config and pause to give it time
    $shellStream.WriteLine("write mem")
    Sleep 5

    # Then, send the backup command to the switch
    $shellStream.WriteLine($backupCommand)
    Sleep 10

    # Finally, logout of the switch and confirm the logout
    $shellStream.WriteLine("logout")
    $shellStream.WriteLine("y")

    # Close the SSH session
    Remove-SSHSession -SSHSession $session
}

# The target backup directory
$backupDir = "\\nas1\d$\NASShare\dr\switches\Automated-Backups"
New-Item $backupDir -ItemType Directory -Force | Out-Null

# Create a log file to keep track of whether or not a switch was backed up
$log = "$backupDir\Switch_Backup_Log.txt"
echo "`n------------------------------------------------" | Out-File -Append $log
echo "Date: $today" | Out-File -Append $log

# Create an array of the desired switches' IP addresses. Creating each
# address as an IPAddress object makes it easier to manipulate later on. 
$switches = @(
    [ipaddress]"172.17.0.1",
    [ipaddress]"172.17.0.3",
    [ipaddress]"172.17.0.4",
    [ipaddress]"172.17.0.5",
    [ipaddress]"172.17.0.6"
    )   
   
# IP of the TFTP server (generally your local IP)
$tftpIP = "172.17.5.96"

# TFTP root directory. For SolarWinds: C:\TFTP-Root
$tftpRoot = "C:\TFTP-Root"

# Start SolarWinds TFTP Server and enable the firewall rule
Start-TftpServer

# Loop through the switches
foreach ($switch in $switches) {

    echo "Backing up switch: $switch..."

    # Set the switch's backup folder
    $switchBackupDir = "$backupDir\$switch"
    New-Item $switchBackupDir -ItemType Directory -Force | Out-Null

    # Log to keep track of changes, if any, to the switch's config
    $switchChangeLog = "$switchBackupDir\ChangeLog.txt"

    # Get the host portion of the IP address, for use in naming the config file
    $hostIP = $switch.GetAddressBytes()[3]

    # What to name the config backup file
    $fileName = "$hostIP-$today.cfg"

    # The backup command to send to the switch
    $backupCommand = "copy startup-config tftp $tftpIP $fileName"

    # SSH into the switch and backup the config
    SSH-BackupSwitch -switch $switch -backupCommand $backupCommand -credentials $credentials

    # Get the name of the most recent copy of the switch's config backup file
    $oldFileName = (Get-ChildItem "$switchBackupDir" -Filter "*.cfg" | Sort LastWriteTime | Select -Last 1).FullName

    # Check to see if there has been a change to the config since last backup
    # If so, store the changed lines in $compareResults
    $compareResults = Compare-Files $oldFileName "$tftpRoot\$fileName"
    
    # If there has been a change to the config 
    If ($compareResults) {
        # Move the config file to the backup directory
        Move-Item "$tftpRoot\$fileName" $switchBackupDir
        echo "Switch $switch backed up on $today." | Out-File -Append $log
        # Write the switch's config changes (the results of Compare-Files) to the change log
        echo $compareResults | Out-File -Append $switchChangeLog
    }
    # If there has not been a change to the config
    Else {
        # Delete the newly created config backup file
        Remove-Item "$tftpRoot\$fileName"
        echo "Switch $switch has not been backed up. No change has been detected." | Out-File -Append $log
    }

    echo "Backup of $switch is complete."
}

# Stop TFTP Service and disable the TFTP firewall rule
Stop-TftpServer

Stop-Transcript