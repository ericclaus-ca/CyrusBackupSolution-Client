<#
.SYNOPSIS
    Calls scripts to backup various services. Part of the Cyrus Backup Solution.
 
.DESCRIPTION
    This script serves as a central piece of the Client aspect of the Cyrus Backup Solution. 
    This script is to be ran from Windows Task Scheduler every 30 minutes. Inside of this
    script, the frequencies for each of the various backup scripts that are part of the 
    Client aspect of the Cyrus Backup Solution are specified and the scripts are called.
    This script provides a central place to manage the frequency of the backups.
  
.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last Modified: 05/15/2018
    Based on code from Shawn Melton (@wsmelton), http://blog.wsmelton.com
 
.LINK
    http://doku/doku.php?id=scripts:cyrus-backup-client
#>
 
# Start a transcript of the Powershell session for logging
$dateTime = (Get-Date).ToString("MM-dd-yyyy_HH-mm")
$scriptName = $MyInvocation.MyCommand.Name
$transcript = "$PSScriptRoot\transcripts\$scriptName.$dateTime.transcript"
Start-Transcript -Path $transcript
  
# Include the neccasary functions
$myFunctions = @(
    "$PSScriptRoot\Backup-Centaur.ps1",
    "$PSScriptRoot\Backup-EOP.ps1",
    "$PSScriptRoot\Backup-FirewallConfig.ps1",
    "$PSScriptRoot\Backup-GPOs.ps1",
    "$PSScriptRoot\Backup-SwitchConfig.ps1",
    "$PSScriptRoot\Backup-Dokuwiki.ps1",
    "$PSScriptRoot\Backup-Spiceworks.ps1",
    "$PSScriptRoot\Backup-Xibo.ps1"
    )
$myFunctions | ForEach-Object {
    If (Test-Path $_) {. $_}
    Else {throw "Error: At least one necessary function was not found. $_"; Exit 99}
}

$dayOfMonth = (Get-Date).Day
$dayOfWeek = (Get-Date).DayOfWeek
$hourOfDay = (Get-Date).Hour # 24 hour time
$minuteOfHour = (Get-Date).Minute

if ($dayOfWeek -eq "Sunday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}
 
if ($dayOfWeek -eq "Monday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}
 
if ($dayOfWeek -eq "Tuesday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}
 
if ($dayOfWeek -eq "Wednesday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}
 
if ($dayOfWeek -eq "Thursday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}
 
if ($dayOfWeek -eq "Friday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}
 
if ($dayOfWeek -eq "Saturday") {
    if ($minuteOfHour -eq 0) {
        Backup-SwitchConfig
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -lt 30) {
        Backup-Dokuwiki
        Backup-Spiceworks
        Backup-Xibo
    }

    if ($hourOfDay -eq 19 -and $minuteOfHour -ge 30) {
        Backup-FirewallConfig
        Backup-GPOs
        Backup-Centaur
    }
}

if ($dayOfMonth -eq 1 -and $hourOfDay -eq 4 -and $minuteOfHour -lt 30) {
    Backup-EOP
}

Stop-Transcript