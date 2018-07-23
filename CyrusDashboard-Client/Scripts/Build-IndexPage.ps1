<#
.SYNOPSIS
    Builds the home page (index.html) for the Cyrus Backup Solution Dashboard.   

.DESCRIPTION
    This script gets a list of all of the backup history pages in the Cyrus Dashboard directory 
    (all HTML files whose names start with "History_"). Then, it compiles the HTML for the index
    page and creates index.html. 

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last modified: 06/28/2018

.LINK
    

.COMPONENT
    Get-ChildItem, Out-File
#>

$ParentDir = Split-Path $PSScriptRoot -Parent

$PageTitle = "Cyrus Dashboard"
$PageHeader = "Welcome to the Dashboard for the Cyrus Backup Solution!"

$LinkList = ""

Get-ChildItem $ParentDir -Filter "History_*.html" | Select-Object Name | 
    ForEach-Object {
        $FileName = $_.Name
        $DisplayName = ($_.Name).Split("_")[1]
        $DisplayName = $DisplayName.Split(".")[0]
        $LinkList += "<a class='history-link' href='$FileName' title='$DisplayName'>$DisplayName</a><br/>"
    }

$Page = @"
<head>
        <title>$PageTitle</title>
        <link href="style.css" rel="stylesheet" type="text/css" />
        <!--JS from https://stackoverflow.com/a/42333464 -->
        <script src="./Scripts/jquery-1.10.2.js"></script>
</head>
<body>
    <!--Nav bar (code modified from https://stackoverflow.com/a/42333464)-->
    <div id="nav-placeholder"></div>
    <script>`$(function(){`$("#nav-placeholder").load("./page_elements/nav-bar.html");});</script>
    <!--end of Navigation bar-->
    
    <div class="page-header">
        <h1>$PageHeader</h1>
        <p>To Do: Switches, GPOs, and AD3 backup histories.</p>
    </div>
    
    <div class="page-content">
        <div class="sub-content">
            <div class="sub-content-head">
                <h3>Backup History Pages</h3>
            </div>
            <div class="history-link-container">
                $LinkList
            </div>
        </div>
    </div>
        
    <!--Footer (code modified from https://stackoverflow.com/a/42333464)-->
    <div id="foot-placeholder"></div>
    <script>`$(function(){`$("#foot-placeholder").load("./page_elements/foot.html");});</script>
    <!--end of Footer-->
</body>
"@

$Page | Out-File "$ParentDir\Index.html" -Encoding ascii