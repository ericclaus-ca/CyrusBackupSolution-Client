function Show-HumanReadableSize {
    <#
    .SYNOPSIS
        Converts a file's size, specified in bytes as an int, to a human readable form.  

    .NOTES
        Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
        Last modified: 06/28/2018
    #>

    param(
        [Parameter(Mandatory=$True)][long]$SizeInBytes
    )

    if ($SizeInBytes -ge 1GB) {$humanReadableSize = "$([math]::Round($SizeInBytes / 1GB,2)) GB"}
    elseif ($SizeInBytes -ge 1MB) {$humanReadableSize = "$([math]::Round($SizeInBytes / 1MB,2)) MB"}
    elseif ($SizeInBytes -ge 1KB) {$humanReadableSize = "$([math]::Round($SizeInBytes / 1KB,2)) KB"}

    return $humanReadableSize
}

function Show-BackupStatus {
    <#
    .SYNOPSIS
        Checks the status of the most recent backup file of a specified item.   

    .DESCRIPTION
        This function gets information about the most recent backup file in a specified directory.
        It checks to see if the Creation Time and Last Modified Time of the file are within
        acceptable ranges (as specefied in the parameters for the function).

    .NOTES
        Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
        Last modified: 06/28/2018

    .COMPONENT
        Show-HumanReadableSize
    #>
    param(
        [Parameter(Mandatory=$True)][string]$Name,
        [Parameter(Mandatory=$True)][string]$BackupDir,
        [string]$FileExtensionWithoutPeriod="*",
        [double]$SizeVariance,
        [int]$CreationDateVariance,
        [int]$LastModifiedDateVatiance
    )

    $mostRecentFile = Get-ChildItem $BackupDir -Filter "*.$FileExtensionWithoutPeriod" | 
        Sort-Object CreationTime | Select-Object -Last 1 | 
        ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                CreationTime = $_.CreationTime
                LastModifiedTime = $_.LastWriteTime
                HumanReadableSize = (Show-HumanReadableSize $_.Length)
                Size = $_.Length
            }
        }

    $mostRecentFile | Select-Object Name, CreationTime, LastModifiedTime, HumanReadableSize

    $averageSizeOfBackups = (Get-ChildItem $BackupDir -Filter "*.$FileExtensionWithoutPeriod" | Measure-Object -Property Length -Average).Average

    $sizeRangeMin = $($averageSizeOfBackups - ($averageSizeOfBackups * $SizeVariance))
    $sizeRangeMax = $($averageSizeOfBackups + ($averageSizeOfBackups * $SizeVariance))

    if (!($mostRecentFile.Size -ge $sizeRangeMin -and $mostRecentFile.Size -le $sizeRangeMax)) {
        $averageSizeOfBackups = Show-HumanReadableSize $averageSizeOfBackups
        Write-Warning "Warning: The size of the most recent $Name backup is outside of the acceptable range of the average size of its backups ($averageSizeOfBackups)!"
    }

    if ($mostRecentFile.CreationTime -ge $((Get-Date).AddDays(-$CreationDateVariance))) {
        Write-Warning "Warning: The creation time of the most recent $Name backup is older than it should be!"
    }



    #return $mostRecentFile
}

#Show-BackupStatus -Name NAS1 -BackupDir Z:\Cyrus\NASShare -FileExtensionWithoutPeriod 7z -SizeVariance 0.01 -CreationDateVariance 3

function Show-BackupStatusHistory {
    <#
    .SYNOPSIS
        Gets a list of all backup files in a specified backup directory.   

    .NOTES
        Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
        Last modified: 06/28/2018

    .COMPONENT
        Show-HumanReadableSize
    #>

    param(
        #[Parameter(Mandatory=$True)][string]$Name,
        [Parameter(Mandatory=$True)][string]$BackupDir,
        [string]$FileExtensionWithoutPeriod="*"
    )

    Get-ChildItem $BackupDir -Filter "*.$FileExtensionWithoutPeriod" | 
        Sort-Object CreationTime -Descending |  ForEach-Object {
        [PSCustomObject]@{
            Name = $_.FullName
            CreationTime = $_.CreationTime
            LastModified = $_.LastWriteTime
            Size = (Show-HumanReadableSize $_.Length)
        }
    }
}

#Show-BackupStatusHistory -Name NAS1 -BackupDir Z:\Cyrus\NASShare -FileExtensionWithoutPeriod 7z
