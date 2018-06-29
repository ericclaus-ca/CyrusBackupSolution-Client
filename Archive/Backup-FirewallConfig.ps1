<#
.SYNOPSIS
    This is a Powershell script to automatically backup the Fotigate config.

.DESCRIPTION
    This script can be used in conjunction with Plink, Solarwinds TFTP server, 
    and Task Scheduler to automate the backup of the firewall's config. 
    If needed, it can support backing up multiple firewalls at once.

Requirements: 
  * The Posh-SSH module must be installed (Install-Module -Name Posh-SSH). 
  * Solarwinds TFTP Server must be installed: http://www.solarwinds.com/free-tools/free-tftp-server
  * A firewall rule named "TFTP" to allow UDP port 69 inbound (it can be disabled). 
  * A secure password file containing the Fortigate BackupAdmin password as a secure string.
  * A secure password file containing the firewall backup encryption key. 
      You can use New-SecurePassFile to generate these files. You can run it manually once to 
      save the secure password (this must be done on the same computer and by the same user 
      account which will be running the Fortigate backup script). Repeat for both secure 
      password files needed for this script.
  * The custom Get-SecurePassword function.

.INPUTS
    This script does not accept any inputs.

.OUTPUTS
    This script does not create any output.

.NOTES
    Author: Eric Claus
    Last Modified: 02/22/2018

.LINK
    http://doku/doku.php?id=dr:fortigate_backup_recovery#automated_backup_using_powershell

.COMPONENT
    Posh-SSH, Get-SecurePassword.ps1, StartStop-SolarwindsTftpServer.ps1
#>

#Requires -Modules Posh-SSH

# Include the Get-SecurePassword and Start/Stop-SolarwindsTftpServer functions
$myFunctions = @(
    "$PSScriptRoot\Get-SecurePassword.ps1",
    "$PSScriptRoot\StartStop-SolarwindsTftpServer.ps1"
    )
$myFunctions | ForEach-Object {
    If (Test-Path $_) {. $_}
    Else {throw "Error: At least one necessary function was not found."; Exit 20}
}

# Start a transcript of the Powershell session for logging
$scriptName = $MyInvocation.MyCommand.Name
$transcript = "$PSScriptRoot\$scriptName.transcript"
Start-Transcript -Path $transcript

$today = (Get-Date).ToString("MM-dd-yyyy_HH-mm")

##### Begin Error Handling #####

# Thanks to Keith Hill for this trap idea.
# https://stackoverflow.com/questions/14246512/send-an-email-if-a-powershell-script-gets-any-errors-at-all-and-terminate-the-sc
function ErrorHandler {
    echo $_
    Stop-TftpServer
    Stop-Transcript
    # Send an email if there are any errors.
    # Thanks to https://www.pdq.com/blog/powershell-send-mailmessage-gmail/ for the code below. 
    $From = "fortigate-log@collegedaleacademy.com"
    $To = "help@collegedaleacademy.com"
    $Attachment = $transcript
    $Subject = "Firewall Config Backup Error"
    $Body = "There has been an error with the automatic backup of the firewall's configuration. See the attached log file for details. -- $_"
    $SMTPServer = "aspmx.l.google.com"
    $SMTPPort = "25"
    Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Attachments $Attachment
}
# If any terminating error occurs, invoke the ErrorHandler function and stop the script
trap {ErrorHandler; Exit 1}
# Treat all errors as terminating, useful for the trap statement above
$ErrorActionPreference = "Stop"

##### End Error Handling #####

##### Begin Credential Management #####

# Username of the backup admin account on the firewall
$userName = "BackupAdmin"
#T he secure password file with it's password
# CHANGE THIS WHENEVER THE SCRIPT IS RUN ON A NEW COMPUTER OR BY A NEW USER
$pwdFile = "$PSScriptRoot\1625998296"
# Create a PSCredential object with the username and password above
$credentials = Get-SecurePassword -PwdFile $pwdFile -userName $userName

# Get the secure password file containing the backup encryption key and convert it to plain text
$encryptionKeyFile = "$PSScriptRoot\1394885258"
$encryptionKey = (Get-SecurePassword $encryptionKeyFile).GetNetworkCredential().Password

##### End Credential Management #####

# The target backup directory
$backupDir = "\\nas1\d$\NASShare\dr\fortinet\Fortigate Config\Automated-Backups\"
New-Item $backupDir -ItemType Directory -Force

# Create a log file to keep track of whether or not a switch was backed up
$log = "$backupDir\Firewall_Backup_Log.txt"
echo "------------------------------------------------" | Out-File -Append $log
echo "Date: $today" | Out-File -Append $log

# Create an array of the IP addressess of the desired firewall(s)
$ipAddresses = @(
    [ipaddress]"172.17.5.2"
    )   

# Your local IP address (the IP of the TFTP server)
# CHANGE THIS WHENEVER THE SCRIPT IS RUN ON A NEW COMPUTER
$tftpServerIP = "172.17.5.96"

# TFTP root directory. For SolarWinds: C:\TFTP-Root
$tftpRoot = "C:\TFTP-Root"

# Start SolarWinds TFTP Server and enable firewall rule
Start-TftpServer

# Loop through the hosts
foreach ($ipAddress in $ipAddresses) {

    echo "Backing up: $ipAddress..."

    # Get the last octet of the IP address, for use in naming the config file
    $hostStr = $ipAddress.GetAddressBytes()[3]

    # Set the host's backup folder
    $hostBackupDir = "$backupDir\$hostStr"
    New-Item $hostBackupDir -ItemType Directory -Force

    # What to name the config backup file
    $fileName = "$hostStr-config-$today.conf"

    # The backup command to send to the host
    $backupCommand = "execute backup config tftp $fileName $tftpServerIP $encryptionKey"

    # Create a new SSH session to the switch
    $session = New-SSHSession -ComputerName $ipAddress -Credential $credentials -AcceptKey:$True
    
    # Send the backup command over SSH
    Invoke-SSHCommand -Command $backupCommand -SSHSession $session

    # Close the SSH session
    Remove-SSHSession -SSHSession $session

    # Move the config file to the backup directory
    Move-Item "$tftpRoot\$fileName" "$hostBackupDir\$fileName"
    
    echo "$ipAddress backed up on $today." | Out-File -Append $log
    
    echo "Backup of $ipAddress is complete."
}

# Stop SolarWinds TFTP Server and disable firewall rule
Stop-TftpServer

Stop-Transcript