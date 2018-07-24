<#
.SYNOPSIS
    Creates HTML pages containing histories of various items backup history.    

.DESCRIPTION
    This script contains a list of all backups, and their backup directories, to check the
    history of. The script takes this list and uses the Show-BackupStatusHistory function
    to get a table containing all backup files for each item being checked. It then creates
    HTML pages containing these tables, one for each backed up item listed in the script.

    Requirements:
        * Must have access to (ie. on the same user account and computer as) the secure password file containing the backup VLAN admin account password.

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last modified: 06/28/2018

.LINK
    

.COMPONENT
    Show-BackupStatusHistory, Get-HtmlContent, ConvertTo-Html, Out-File
#>

$ParentDir = Split-Path $PSScriptRoot -Parent

. "$PSScriptRoot\Show-BackupStatus.ps1"
. "$PSScriptRoot\Get-HtmlContent.ps1"
. "$PSScriptRoot\Get-SecurePassword.ps1"

# Paths to NAS and VM backup directories
$nasDr = "\\192.168.90.92\d$\NASShare\dr"
$vmDr = "V:\VM_Backup"

# Create a PSCredential object with the password for the domain backup VLAN admin account
$securePassFile = "$ParentDir\Other\1088405980"
$userName = "ad\Cyrus"
$creds = Get-SecurePassword -PwdFile $securePassFile -userName $userName
      
# Create a temporary mapped drive, connecting to the NAS backup directory with the credentials from above
Remove-PSDrive -Name "tempSource" -ErrorAction SilentlyContinue
New-PSDrive -Name "tempSource" -PSProvider FileSystem -Root $nasDr -Credential $creds
$nasDr = "tempSource:\"

# Backup directory for the network switches
$switchDr = "$nasDr\switches\Automated-Backups"

# A list of items to display backup history for (most of the items backed up by Cyrus Backup Solution)
$BackupDirs = 
    @(
        #@("Backup directory path","File name for the HTML file","HTML page title")
        @("$nasDr\fortinet\Fortigate Config\Automated-Backups\2\","History_Network-Fortigate Config","Fortigate Config Backup History"),
        @("$nasDr\fortinet\FSSO Config\","History_FSSO Config","FSSO Config Backup History"),
        @("$nasDr\fortinet\FortiClient EMS DB\","History_EMS","EMS DB Backup History"),
        @("$nasDr\EveryonePrint","History_EveryonePrint","EveryonePrint Backup History"),
        @("$nasDr\dokuwiki","History_Dokuwiki","Dokuwiki Backup History"),
        @("$nasDr\spiceworks","History_Spiceworks","Spiceworks Backup History"),
        @("$nasDr\Centurion","History_Centurion","Centurion Backup History"),
        @("$nasDr\HiveManager","History_HiveManager","HiveManager Backup History"),
        @("$nasDr\UMRA","History_UMRA","UMRA Backup History"),
        @("$nasDr\Centaur","History_Centaur","Centaur Backup History"),
        @("$nasDr\FruitServer","History_Fruit Server","FruitServer Backup History"),
        @("$nasDr\Xibo","History_Xibo","Xibo Backup History"),
        @("$vmDr\AD3","History_VM-AD3","AD3 Backup History"),
        @("$vmDr\Centurion1","History_VM-Centurion1","Centurion1 Backup History"),
        @("$vmDr\CyrusClient1","History_VM-CyrusClient1","CyrusClient1 Backup History"),
        @("$vmDr\Dokuwiki1","History_VM-Dokuwiki1","Dokuwiki1 Backup History"),
        @("$vmDr\EP-MG1","History_VM-EP-MG1","EP-MG1 Backup History"),
        @("$vmDr\FortiClientEMS1","History_VM-FortiClientEMS1","FortiClientEMS1 Backup History"),
        @("$vmDr\FruitServer1","History_VM-FruitServer1","FruitServer1 Backup History"),
        @("$vmDr\Pandora","History_VM-Pandora1","Pandora1 Backup History"),
        @("$vmDr\Print1","History_VM-Print1","Print1 Backup History"),
        @("$vmDr\sccm16-01","History_VM-sccm16-01","sccm16-01 Backup History"),
        @("$vmDr\spiceworks1","History_VM-Spiceworks1","Spiceworks1 Backup History"),
        @("$vmDr\Sync1","History_VM-Sync1","Sync1 Backup History"),
        @("$vmDr\WSUS","History_VM-WSUS","WSUS Backup History"),
        @("Z:\Cyrus\NASShare","History_Network-NASShare","NAS1 Backup History","7z"),
        @("$nasDr\GPO\Logs","History_GPO","GPO Backup History"),
        @("$switchDr\172.17.0.1","History_Network-Core Switch","Core Switch Backup History","cfg"),
        @("$switchDr\172.17.0.3","History_Network-Business Office Switch","Business Office Switch Backup History","cfg"),
        @("$switchDr\172.17.0.4","History_Network-Gym Switch","Gym Switch Backup History","cfg"),
        @("$switchDr\172.17.0.5","History_Network-Band Switch","Band Switch Backup History","cfg"),
        @("$switchDr\172.17.0.6","History_Network-Help Desk Switch","Help Desk Switch Backup History","cfg")
    )

foreach ($dir in $BackupDirs) {
    $Head, $PreContent, $PostContent = Get-HtmlContent -PageTitle $($dir[2]) -PageHeader $dir[2]

    $fileName = $dir[1]
    if ($fileName -notlike "*.html") {$fileName = "$fileName.html"}

    # If a file type is specified in the array above, if not show files of all types
    if ($dir[3]) {$fileExtension = $dir[3]}
    else {$fileExtension = "*"}

    Show-BackupStatusHistory -BackupDir $dir[0] -FileExtensionWithoutPeriod $fileExtension | 
        ConvertTo-Html -Head $Head -PreContent $PreContent -PostContent $PostContent | 
        Out-File -Encoding ascii "C:\Scripts\Cyrus-Backup-Server\CyrusDashboard\$fileName"
}

& "$PSScriptRoot\Build-IndexPage.ps1"

# The drive created should be removed once the Powershell session ends, however, this makes sure it goes away
Remove-PSDrive -Name "tempSource" -ErrorAction SilentlyContinue