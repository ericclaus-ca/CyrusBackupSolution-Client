    <#
    .SYNOPSIS
     
     
    .DESCRIPTION
     
     
    .EXAMPLE
     
     
    .EXAMPLE
     
     
    .NOTES
        Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
        Last Modified: 05/04/2018
        Based on code from Shawn Melton (@wsmelton), http://blog.wsmelton.com
     
    .LINK
        http://doku/doku.php?id=scripts:cyrus-backup-client
    #>
     
    # Start a transcript of the Powershell session for logging
    $scriptName = $MyInvocation.MyCommand.Name
    $transcript = "$PSScriptRoot\$scriptName.transcript"
    Start-Transcript -Path $transcript
        
    # Include the neccasary functions
    $myFunctions = @(
        "$PSScriptRoot\Backup-Centaur.ps1",
        "$PSScriptRoot\Backup-EOP.ps1",
        "$PSScriptRoot\Backup-FirewallConfig.ps1",
        "$PSScriptRoot\Backup-GPOs.ps1",
        "$PSScriptRoot\Backup-SwitchConfig.ps1"
        )
    $myFunctions | ForEach-Object {
        If (Test-Path $_) {. $_}
        Else {throw "Error: At least one necessary function was not found."; Exit 99}
    }
     <#
    $dayOfWeek = (Get-Date).DayOfWeek
    $hourOfDay = (Get-Date).Hour
     
    if ($dayOfWeek -eq "Sunday") {
        if ($hourOfDay -eq 20) {
            # Backup the VMs
            Backup-VM -vmNames "ad3" -hypervisorName $Isaac -backupDirectory "$target\ad3"
            Backup-VM -vmNames "Centurion1" -hypervisorName $Isaac -backupDirectory "$target\Centurion1"
            Backup-VM -vmNames "Dokuwiki1" -hypervisorName $Isaac -backupDirectory "$target\Dokuwiki1" -disableQuiesce $true
            Backup-VM -vmNames "EP-MG1" -hypervisorName $Isaac -backupDirectory "$target\EP-MG1"
            Backup-VM -vmNames "FortiClientEMS1" -hypervisorName $Isaac -backupDirectory "$target\FortiClientEMS1"
            Backup-VM -vmNames "Pandora" -hypervisorName $Isaac -backupDirectory "$target\Pandora" -disableQuiesce $true
            Backup-VM -vmNames "Print1" -hypervisorName $Isaac -backupDirectory "$target\Print1"
            Backup-VM -vmNames "spiceworks1" -hypervisorName $Isaac -backupDirectory "$target\spiceworks1"
            Backup-VM -vmNames "Sync1" -hypervisorName $Isaac -backupDirectory "$target\Sync1"    
     
            # If is is the first week of the month
            if ((Get-Date).Day -le 7) {
                Backup-VM -vmNames "sccm16-01" -hypervisorName $Isaac -backupDirectory "$target\sccm16-01"
            }
        }
    }
     
    if ($dayOfWeek -eq "Monday") {
        Backup-NAS1 -Type Incremental
    }
     
    if ($dayOfWeek -eq "Tuesday") {
        Backup-NAS1 -Type Incremental
    }
     
    if ($dayOfWeek -eq "Wednesday") {
        Backup-NAS1 -Type Incremental
    }
     
    if ($dayOfWeek -eq "Thursday") {
        Backup-NAS1 -Type Incremental
    }
     
    if ($dayOfWeek -eq "Friday") {
        #if ($hourOfDay -eq 20) {
            # Perform a full backup of the file shares on NAS1
            Backup-NAS1 -Type Full
        #}
    }
     
    if ($dayOfWeek -eq "Saturday") {
    }
     
     
    # "Clean up" (delete) backups older than their retention period
    $backupDir = "\\192.168.90.92\d$\NASShare\dr"
    Cleanup-Backups -BackupName "Dokuwiki" -DaysOldToKeep 31 -BackupFolder "$backupDir\dokuwiki"
    Cleanup-Backups -BackupName "Spiceworks" -DaysOldToKeep 31 -BackupFolder "$backupDir\spiceworks"
    Cleanup-Backups -BackupName "Fortigate" -DaysOldToKeep 365 -BackupFolder "$backupDir\fortinet\Fortigate Config"
    Cleanup-Backups -BackupName "Centaur" -DaysOldToKeep 7 -BackupFolder "$backupDir\Centaur"
    Cleanup-Backups -BackupName "EOP" -DaysOldToKeep 90 -BackupFolder "$backupDir\EveryonePrint"
    Cleanup-Backups -BackupName "NAS" -DaysOldToKeep 56 -BackupFolder "Z:\Cyrus\NASShare"
    Cleanup-Backups -BackupName "VMs" -DaysOldToKeep 90 -BackupFolder "V:\VM_Backup"
     #>
    Stop-Transcript

