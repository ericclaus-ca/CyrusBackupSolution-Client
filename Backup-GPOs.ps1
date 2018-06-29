<#
.SYNOPSIS
    This is a Powershell script to automatically backup all GPOs.

.DESCRIPTION
    This script can be used in conjunction with Task Scheduler to automate 
    the backup of all group policy objects. It performs an incremental backup
    and only backs up GPOs that have been modified since their last backup.
    If there are any errors, the script will create an email ticket.

    Remote Server Administration Tools (RSAT) needs to be installed in order
    for the grouppolicy module, needed by this script, to import.

    Thanks to Matt Browne, MattB101, for his script named GPO_Backup.ps1. 
    The incremental backup part of this script is based upon his script.
    The link to his script is in the LINK section.

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last Modified: 05/07/2018

.LINK
    http://doku/doku.php?id=dr:gpo_backup
    https://gallery.technet.microsoft.com/scriptcenter/Incremental-GPO-Backup-ccc0856f

.COMPONENT
    RSAT, PS module grouppolicy
#>
function Backup-GPOs {
    $date = Get-Date -Format d | foreach {$_ -replace "/", "-"}
    $log = "\\nas1\d$\NASShare\dr\GPO\Logs\Backuplog-$date.log"
    echo $date | Out-File $log
    # Useful for the Try/Catch used below 
    $ErrorActionPreference = "Stop"

    # If, and only if, there are any errors in the commands within the Try block, the script will skip down 
    # to the Catch block, submitting an email ticket, and then exit.
    Try {
        # Import required module
        Import-Module grouppolicy
    
        # Get all GPOs and loop through them
        Foreach ($GPO in $(Get-GPO -All)) {
            $name = $GPO.DisplayName
            $lastModified = $GPO.ModificationTime
        
            # Set the path to the backup directory, named for the GPO and it's modification date
            $path = "\\nas1\d$\NASShare\dr\GPO\Incremental\$name\$lastModified"
            $path = $path -replace ':','-'
            $path = $path -replace '/','-'
            $path = $path -replace ' ','_'
        
            # Check if the GPO has been modified since it was last backed up by
            # checking to see if there is already a backup folder by the same name.
            If (!(Test-Path $path)) {
                mkdir $path
                Backup-GPO -Name $name -Path $path
                echo ("{0} has been backed up." -f $name.PadRight(40,"-")) | Tee-Object -FilePath $log -Append
            }
            Else {echo ("{0} not backed up." -f $name.PadRight(40,"-")) | Tee-Object -FilePath $log -Append}
        }
    }
    Catch {
        echo $_
        # Thanks to https://www.pdq.com/blog/powershell-send-mailmessage-gmail/ for the code below. 
        ##############################################################################
        $From = "fortigate-log@collegedaleacademy.com"
        $To = "help@collegedaleacademy.com"
        $Subject = "GPO Backup Error"
        $Body = "There has been an error with the automated backup of the GPOs. See the attached log file for details."
        $SMTPServer = "aspmx.l.google.com"
        $SMTPPort = "25"
        Send-MailMessage -From $From -to $To -Attachments $log -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl
        ##############################################################################
    }
}