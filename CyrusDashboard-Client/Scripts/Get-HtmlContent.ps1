function Get-HtmlContent {
<#
.SYNOPSIS
    Builds the HTML header and other parts of HTL pages excluding the tables created
    dynamically via the Build-HtmlPages.ps1 script.   

.NOTES
    Author: Eric Claus, IT Assistant, Collegedale Academy, ericclaus@collegedaleacademy.com
    Last modified: 06/28/2018

.LINK
    

#>

param(
    [Parameter(Mandatory=$True)][string]$PageTitle,
    [Parameter(Mandatory=$True)][string]$PageHeader
)

$Head = @"
    <title>$PageTitle</title>
    <link href="style.css" rel="stylesheet" type="text/css" />
    <!-- Sorting Javascript script from: https://www.kryogenix.org/code/browser/sorttable/ -->
    <script src="./Scripts/sorttable.js"></script>
    <!--JS from https://stackoverflow.com/a/42333464 -->
    <script src="./Scripts/jquery-1.10.2.js"></script>
"@

$PreContent = @"
  <!--Nav bar (code modified from https://stackoverflow.com/a/42333464)-->
  <div id="nav-placeholder"></div>
  <script>`$(function(){`$("#nav-placeholder").load("./page_elements/nav-bar.html");});</script>
  <!--end of Navigation bar-->

  <div class="page-header">
      <h1>$PageHeader</h1>
  </div>
  <div class="page-content">
  <div class="table-container">

"@

$PostContent = @"
</div>
</div>

  <!--Footer (code modified from https://stackoverflow.com/a/42333464)-->
  <div id="foot-placeholder"></div>
  <script>`$(function(){`$("#foot-placeholder").load("./page_elements/foot.html");});</script>
  <!--end of Footer-->
"@

return @($Head,$PreContent,$PostContent)

}