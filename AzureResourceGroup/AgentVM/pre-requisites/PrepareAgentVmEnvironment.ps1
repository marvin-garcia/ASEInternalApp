param(
    [Parameter(Mandatory=$false, ParameterSetName="agentvm")]
    [String]$AdminUsername = "EnterpriseAdmin",

    [Parameter(Mandatory=$true, ParameterSetName="agentvm")]
    [securestring]$AdminPassword,
   
    [Parameter(Mandatory=$true, ParameterSetName="agentvm")]
    [String]$VSTSProjectName,

    [Parameter(Mandatory=$true, ParameterSetName="agentvm")]
    [String]$AgentPool,

    [Parameter(Mandatory=$true, ParameterSetName="agentvm")]
    [String]$PersonalAccessToken,

	[Parameter(Mandatory=$true, ParameterSetName="agentvm")]
    [String]$AseIP,

	[Parameter(Mandatory)]
    [String]$ArtifactsLocation,

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

#region Agent VM
$templateParameters.Add("AdminUsername", @{ "value" = $AdminUsername})
$templateParameters.Add("AdminPassword", @{ "value" = (New-Object PSCredential "user", $AdminPassword).GetNetworkCredential().Password})
$templateParameters.Add("TSServerUrl", @{ "value" = "https://$($VSTSProjectName).visualstudio.com"})
$templateParameters.Add("AgentPool", @{ "value" = $AgentPool})
$templateParameters.Add("PAToken", @{ "value" = $PersonalAccessToken})
$templateParameters.Add("AseIP", @{ "value" = $AseIP})
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