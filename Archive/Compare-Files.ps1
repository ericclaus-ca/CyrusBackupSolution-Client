function Compare-Files {
    <#
    .SYNOPSIS
        Compare two files and return any changes.
    
    .DESCRIPTION
        Compare-Files uses Compare-Object to compare two files. It outputs
        the differences between the two files in a formatted table. By
        setting the -IncludeEqual flag, it can return all of the lines 
        that are unchanged, as well. 

        If differences between the two files are found, an array containing
        the differences is returned. The output has the format:

        Line Number    <name of older file>    <name of newer file>    Action
        -----------    --------------------    --------------------    ------
                  4    This is a line of text                          Removed
                 12                            A new line of text      Added    

    .INPUTS
        This script does not accept any piped inputs.
    
    .OUTPUTS
        None, or [System.Array]
    
    .NOTES
        Author: Eric Claus
        Last Modified: 02/22/2018
    
        Thanks to Lee Holmes for his Compare-File script, from which this is based.
    
    .LINK
        http://doku/doku.php?id=other:compare-files
        http://www.leeholmes.com/blog/2013/11/29/using-powershell-to-compare-diff-files/
    
    .COMPONENT
        Compare-Object
    #>
    
    Param(
        [Parameter(Mandatory=$True)][string]$oldFile,
        [Parameter(Mandatory=$True)][string]$newFile,
        [switch]$IncludeEqual
    )

    # Get the file names from the full paths
    $oldName = Split-Path -Path $oldFile -Leaf
    $newName = Split-Path -Path $newFile -Leaf

    $oldContents = Get-Content $oldFile
    $newContents = Get-Content $newFile
    
    # Compare the two files, sort the lines by line number, and loop through them
    Compare-Object $oldContents $newContents -IncludeEqual:$IncludeEqual | Sort-Object {$_.InputObject.ReadCount} | ForEach-Object {
        
        $line = "$($_.InputObject)"
        
        # What change was made to the line
        Switch ($_.SideIndicator) {
            "==" {$action = ""; $oldLine = $newLine = $line}
            "=>" {$action = "Added"; $oldLine = ""; $newLine = $line}
            "<=" {$action = "Removed"; $oldLine = $line; $newLine = ""}
        }
    
        # Return a PSCustomObject, creates an array when returned multiple times
        [PSCustomObject] @{
            "Line Number" = $_.InputObject.ReadCount
            $oldName = $oldLine
            $newName = $newLine
            Action = $action
        }
    }
}