cls
C:\users\magar\source\repos\ASEInternalApp\AzureResourceGroup\WebAppILBASE\pre-requisites\PrepareAseEnvironment.ps1 `
    -DomainName 'corp-internal.com' `
    -CertificatePath 'C:\Users\magar\AppData\Local\Temp\tmpB2DB.tmp' `
    -CertificatePassword (ConvertTo-SecureString 'P@$$w0rd!!' -AsPlainText -Force) `
    -AdminUsername 'EnterpriseAdmin' `
    -AdminPassword (ConvertTo-SecureString 'P@$$w0rd!!' -AsPlainText -Force) `
    -VSTSProjectName 'marv-playground' `
    -AgentPool 'agentpool' `
    -PersonalAccessToken '2zegwwxroswe5iamp6jq2nwg4cwxiunzjkqhedygs5n3apwyn6ca' `
    -VnetResourceGroupName 'TextronLab' `
    -VnetName 'Corp1' `
    -OutFile 'C:\users\magar\source\repos\ASEInternalApp\AzureResourceGroup\WebAppILBASE\azuredeploy.parameters.json'
