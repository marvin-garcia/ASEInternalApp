[CmdletBinding(DefaultParameterSetName="nodevops")]
param(
    [Parameter(Mandatory=$false)]
    [String]$CertificatePath,

    [Parameter(Mandatory)]
    [securestring]$CertificatePassword,

    [Parameter(Mandatory)]
    [String]$DomainName,

    [Parameter(Mandatory=$false, ParameterSetName="devops")]
    [String]$AdminUsername = "EnterpriseAdmin",

    [Parameter(Mandatory=$true, ParameterSetName="devops")]
    [securestring]$AdminPassword,
   
    [Parameter(Mandatory=$true, ParameterSetName="devops")]
    [String]$VSTSProjectName,

    [Parameter(Mandatory=$true, ParameterSetName="devops")]
    [String]$AgentPool,

    [Parameter(Mandatory=$true, ParameterSetName="devops")]
    [String]$PersonalAccessToken,

    [Parameter(Mandatory=$false)]
    [String]$OutFile=".\azuredeploy.parameters.json",
    
    [Parameter(Mandatory)]
    [String]$VnetResourceGroupName,

    [Parameter(Mandatory)]
    [String]$VnetName
)

#Check if the user is administrator
if (-not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))
{
    throw "You must have administrator priveleges to run this script."
}

if ([String]::IsNullOrEmpty($CertificatePath))
{
    $CertificatePath = [System.IO.Path]::GetTempFileName()
    Write-Host "Certificate file stored in $CertificatePath"

    $certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "*.$DomainName","*.scm.$DomainName"
    $certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint    
    Export-PfxCertificate -cert $certThumbprint -FilePath $CertificatePath -Password $CertificatePassword
}
else
{
    $certificate = Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $CertificatePath -Password $CertificatePassword
    $certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint    
}

$fileContentBytes = Get-Content $CertificatePath -Encoding Byte
$pfxBlobString = [System.Convert]::ToBase64String($fileContentBytes)

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $VnetResourceGroupName -Name $VnetName

$TSServerUrl = "https://$($VSTSProjectName).visualstudio.com"

$templateParameters = @{}

$templateParameters.Add("vnetId", @{ "value" = $vnet.Id })
$templateParameters.Add("aseSubnetName", @{ "value" = "" })
$templateParameters.Add("agentSubnetName", @{ "value" = "" })
$templateParameters.Add("aseName", @{ "value" = "" })
$templateParameters.Add("internalLoadBalancingMode", @{ "value" = 3 })
$templateParameters.Add("pricingTier", @{ "value" = "1" })
$templateParameters.Add("capacity", @{ "value" = 1 })
$templateParameters.Add("appServicePlanName", @{ "value" = "" })
$templateParameters.Add("aseSiteName", @{ "value" = "" })
$templateParameters.Add("pfxBlobString", @{ "value" = $pfxBlobString })
$templateParameters.Add("certificateName", @{ "value" = "$($DomainName).pfx" })
$templateParameters.Add("certificatePassword", @{ "value" = (New-Object PSCredential "user", $CertificatePassword).GetNetworkCredential().Password })
$templateParameters.Add("certificateThumbprint", @{ "value" = $certificate.Thumbprint })
$templateParameters.Add("domainName", @{ "value" = $DomainName })
$templateParameters.Add("_artifactsLocation", @{ "value" = "https://ilbasetemplates.blob.core.windows.net" })

if (-not [String]::IsNullOrEmpty($AdminPassword))
{
    $templateParameters.Add("AdminUsername", @{ "value" = $AdminUsername})
    $templateParameters.Add("AdminPassword", @{ "value" = (New-Object PSCredential "user", $AdminPassword).GetNetworkCredential().Password})
    $templateParameters.Add("TSServerUrl", @{ "value" = $TSServerUrl})
    $templateParameters.Add("AgentPool", @{ "value" = $AgentPool})
    $templateParameters.Add("PAToken", @{ "value" = $PersonalAccessToken})
}


$templateParameters | ConvertTo-Json -Depth 10 | Out-File $OutFile

Write-Host "Parameters written to $OutFile."