param(
    #Website related parameters
    [string]$InstanceId = 'you_sitecore_id',
    [bool]$DnsSuffixMode = $TRUE,
    [string]$IISRootPath = 'C:\inetpub\wwwroot\',
    #Database related parameters
    [string]$SQLInstanceName = 'your_SQL_instance_name',
    [string]$SQLUsername = 'SQLUsername',
    [string]$SQLPassword = 'SQLPassword',
    #Certificate related parameters
    [string]$CertificateRootStore = 'Cert:\Localmachine\Root',
    [string]$CertificatePersonalStore = 'Cert:\Localmachine\My',
    #Solr related parameters
    [string]$SolrPath = 'C:\solr'
)

Import-Module SQLPS
$SitecoreWebsiteName = "local"
if ($DNSSuffixMode)
{
    $SitecoreWebsiteName = $SitecoreWebsiteName + "." + $InstanceID
}
else
{
    $SitecoreWebsiteName = $InstanceID + "." + $SitecoreWebsiteName
}
$SSLCertName = "$SitecoreWebsiteName"
$SitecoreWebsiteName = "$SitecoreWebsiteName"
$SitecoreWebsitePhysicalPath = "$IISRootPath$SitecoreWebsiteName"
$HostFileLocation = "c:\windows\system32\drivers\etc\hosts"
Write-Host -foregroundcolor Green  "Starting Sitecore 9 instance removal..."

#Remove Sitecore website
Write-Host -foregroundcolor Green  "[1/7] Remove hosts entries..."
if([bool](Get-Website $SitecoreWebsiteName)) {
    Write-host -foregroundcolor Green "Deleting Website $SitecoreWebsiteName"
    Remove-WebSite -Name $SitecoreWebsiteName
    Write-host -foregroundcolor Green "Deleting App Pool $SitecoreWebsiteName"
    Remove-WebAppPool $SitecoreWebsiteName
}
else {
    Write-host -foregroundcolor Red "Website $SitecoreWebsiteName does not exists."
}
#Remove hosts entries
Write-Host -foregroundcolor Green  "[2/7] Remove hosts entries..."
if([bool]((get-content $HostFileLocation) -match "127.0.0.1\s(.+)$InstanceId")) {
    Write-Host -foregroundcolor Green  "Deleting hosts entries."
    (get-content $HostFileLocation) -notmatch "127.0.0.1\s(.+)$InstanceId" | Out-File $HostFileLocation
}
else {
    Write-Host -foregroundcolor Red  "No hosts entires found."
}
if([bool]((get-content $HostFileLocation) -match "127.0.0.1\s(.+)$InstanceId")) {
    Write-Host -foregroundcolor Green  "Deleting hosts entries."
    (get-content $HostFileLocation) -notmatch "127.0.0.1\s(.+)$InstanceId" | Out-File $HostFileLocation
}
else {
    Write-Host -foregroundcolor Red  "No hosts entires found."
}
#Remove Sitecore Files
Write-Host -foregroundcolor Green  "[3/7] Remove Sitecore Files..."
if (Test-Path $SitecoreWebsitePhysicalPath) { 
    Remove-Item -path $SitecoreWebsitePhysicalPath\* -recurse 
    Remove-Item -path $SitecoreWebsitePhysicalPath 
    Write-host -foregroundcolor Green $SitecoreWebsitePhysicalPath " Deleted" 
    [System.Threading.Thread]::Sleep(1500) 
} else { 
    Write-host -foregroundcolor Red  $SitecoreWebsitePhysicalPath  " Does not exist" 
}
#Remove SQL Databases
Write-Host -foregroundcolor Green  "[4/7] Remove SQL Databases..."
$DBList = New-Object System.Collections.ArrayList
Get-SqlDatabase -ServerInstance $SQLInstanceName |
where { $_.name -like "$InstanceID*" } | foreach {
    [void]$DBList.Add($_.name)
}
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($SQLInstanceName)
ForEach($DB in $DBList) {
    Write-host -foregroundcolor Green "Deleting Database $DB"
    $server.databases[$DB].Drop()
}
#Remove Certificates
Write-Host -foregroundcolor Green  "[5/7] Remove Certificates..."
if([bool](Get-ChildItem -Path $CertificatePersonalStore -dnsname $SSLCertName)) {
    Write-host -foregroundcolor Green "Deleting certificate " $SSLCertName
    Get-ChildItem -Path $CertificatePersonalStore -dnsname $SSLCertName | Remove-Item
}
else {
    Write-host -foregroundcolor Red "Certificate " $SSLCertName " does not exists."
}
if([bool](Get-ChildItem -Path $CertificateRootStore -dnsname $SSLCertName)) {
    Write-host -foregroundcolor Green "Deleting certificate " $SSLCertName
    Get-ChildItem -Path $CertificateRootStore -dnsname $SSLCertName | Remove-Item
}
else {
    Write-host -foregroundcolor Red "Certificate " $SSLCertName " does not exists."
}
# Remove Solr Cores
Write-Host -foregroundcolor Green  "[6/7] Remove Solr Cores..."
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_core_index")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_master_index")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_web_index")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_marketingdefinitions_master")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_marketingdefinitions_web")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_marketing_asset_index_master")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_marketing_asset_index_web")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_testing_index")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_suggested_test_index")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_fxm_master_index")
& "$SolrPath\bin\solr.cmd" delete -c ($InstanceId + "_fxm_web_index")
# Remove Application Users
Write-Host -foregroundcolor Green  "[7/7] Remove Application Users..."
$UserObj = Get-WmiObject Win32_UserProfile -filter "localpath='C:\\Users\\$SitecoreWebsiteName'"
$UserObj.Delete()
Write-Host -foregroundcolor Green  "Finished Sitecore 9 instance removal."
