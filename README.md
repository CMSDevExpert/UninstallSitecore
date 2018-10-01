# UninstallSitecore
This PS Script will help you remove a Sitecore 9 instance from your Server

# How to use 
1. Edit the Pram section to point your :
- Sitecore 9 instance (Hostname and IIS root path),
- acces to your SQL Server,
- Path to your SSL Certificates
- Path to sorl instance

2. Execute with admin privileges

## Example
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
