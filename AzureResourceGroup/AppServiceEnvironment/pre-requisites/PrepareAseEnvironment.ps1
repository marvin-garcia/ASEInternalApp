param(
    [Parameter(Mandatory)]
    [String]$DomainName,
	    
    [Parameter(Mandatory=$false)]
    [String]$CertificatePath,

    [Parameter(Mandatory)]
    [securestring]$CertificatePassword,

    [Parameter(Mandatory)]
    [String]$VnetResourceGroupName,

    [Parameter(Mandatory)]
    [String]$VnetName,

	[Parameter(Mandatory)]
    [String]$SubnetName,

	[Parameter(Mandatory=$false)]
    [String]$OutFile = ".\azuredeploy.parameters.json"
)

# Check if the user is administrator
if (-not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))
{
    throw "You must have administrator priveleges to run this script."
}

#region Handle certificate

# If no certificate file is passed, create self-signed cert
if ([String]::IsNullOrEmpty($CertificatePath))
{
    $CertificatePath = [System.IO.Path]::GetTempFileName()
    Write-Host "Certificate file stored in $CertificatePath"

    $certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname "*.$DomainName","*.scm.$DomainName"
    $certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint    
    Export-PfxCertificate -cert $certThumbprint -FilePath $CertificatePath -Password $CertificatePassword
}
# Import PFX cert
else
{
    $certificate = Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath $CertificatePath -Password $CertificatePassword
    $certThumbprint = "cert:\localMachine\my\" + $certificate.Thumbprint    
}

$fileContentBytes = Get-Content $CertificatePath -Encoding Byte
$pfxBlobString = [System.Convert]::ToBase64String($fileContentBytes)
#endregion

#region Get vnet settings
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $VnetResourceGroupName -Name $VnetName
$subnet = $vnet.Subnets | ? { $_.Name -eq $SubnetName }
$subnetId = $subnet.Id
#endregion

#region Add parameters
$templateParameters = @{}
$templateParameters.Add("subnetId", @{ "value" = $subnetId })
$templateParameters.Add("aseName", @{ "value" = "" })
$templateParameters.Add("domainName", @{ "value" = $DomainName })
$templateParameters.Add("internalLoadBalancingMode", @{ "value" = 3 })
$templateParameters.Add("pfxBlobString", @{ "value" = $pfxBlobString })
$templateParameters.Add("certificatePassword", @{ "value" = (New-Object PSCredential "user", $CertificatePassword).GetNetworkCredential().Password })
$templateParameters.Add("certificateThumbprint", @{ "value" = $certificate.Thumbprint })
$templateParameters.Add("appServicePlanName", @{ "value" = "" })
$templateParameters.Add("siteName", @{ "value" = "" })
$templateParameters.Add("pricingTier", @{ "value" = "1" })
$templateParameters.Add("capacity", @{ "value" = 1 })
$templateParameters.Add("_artifactsLocation", @{ "value" = "" })

$templateParameters | ConvertTo-Json -Depth 10 | Out-File $OutFile

Write-Host "Parameters written to $OutFile."
#endregion