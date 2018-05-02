param(
    [Parameter(Mandatory=$false, ParameterSetName="aseenv")]
    [String]$CertificatePath,

    [Parameter(Mandatory, ParameterSetName="aseenv")]
    [securestring]$CertificatePassword,

    [Parameter(Mandatory, ParameterSetName="aseenv")]
    [String]$DomainName,
	    
    [Parameter(Mandatory, ParameterSetName="aseenv")]
    [String]$VnetResourceGroupName,

    [Parameter(Mandatory, ParameterSetName="aseenv")]
    [String]$VnetName,

	[Parameter(Mandatory=$false)]
    [String]$ArtifactsLocation = "https://github.com/marvin-garcia/ASEInternalApp/raw/master/AzureResourceGroup",

	[Parameter(Mandatory)]
	[Switch]$SaveToFile,

    [Parameter(Mandatory=$false)]
    [String]$OutFile=".\azuredeploy.parameters.json"
)

# Check if the user is administrator
if (-not [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))
{
    throw "You must have administrator priveleges to run this script."
}

# Initialize parameters object
$templateParameters = @{}
$templateParameters.Add("_artifactsLocation", @{ "value" = $ArtifactsLocation })

#region ASE env

#region Read certificate
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
#endregion

#region Get vnet settings
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $VnetResourceGroupName -Name $VnetName
$vnetId = $vnet.Id
#endregion

#region Add parameters
$templateParameters.Add("vnetId", @{ "value" = $vnetId })
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
#endregion

#endregion

if ($SaveToFile)
{
	$templateParameters | ConvertTo-Json -Depth 10 | Out-File $OutFile

	Write-Host "Parameters written to $OutFile."
}
else
{
	return $templateParameters
}