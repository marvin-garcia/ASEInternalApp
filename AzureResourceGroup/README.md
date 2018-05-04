# AzureResourceGroup

This solution contains the required ARM templates to deploy a DevOps ILB ASE web app on Azure. It is separated in four different Azure Resource Group projects: `AgentVM`, `AppServiceEnvironment`, `AseWebApp` and `DevOpsAse`. The latter template will create the whole environment by making use of all the other templates. You can also use any of these templates separately based on your needs, some of the use cases are:
*	Need to deploy a new build agent VM to expand your pool on VSTS/TFS.
*	Need to deploy a new App Service Environment (ASE) to host new web apps.
*	New to deploy a new web app on an existing ASE.

### AgentVM
This [template](AzureResourceGroup/AgentVM/azuredeploy.json) will:
*	Create a windows virtual machine on your subscription, 
*	configure it as a build agent,
*	and add it to an existing agent pool in your VSTS/TFS account.

### AppServiceEnvironment
This [template](AzureResourceGroup/AppServiceEnvironment/azuredeploy.json) will:
*	Create an App Service Environment on your subscription inside an existing virtual network. (**NOTE: for this deployment to work, the specified subnet must be empty prior to the deployment**),
*	apply the SSL certificate for the internal load balancer,
*	and create a new web app with an app service plan. (**NOTE: If you don’t want to create the web app, you can leave the parameter `siteName` empty and it will skip that step**).

**NOTE: The PowerShell script [PrepareAseEviroment.ps1](AzureResourceGroup/AppServiceEnvironment/pre-requisites/PrepareAseEnvironment.ps1) will handle the SSL certificate setup for the ILB and auto populate some of the parameters that are required by the deployment.**

### AseWebApp
This [template](AzureResourceGroup/AseWebApp/azuredeploy.json) will create an app service plan and a web app site inside the specified App Service Environment.

### DevOpsAse
This [template](AzureResourceGroup/DevOpsAse/azuredeploy.json) will call the AppServiceEnvironment and AgentVM templates to deploy a new build agent VM and an ASE inside an existing virtual network. The PowerShell script [PrepateDevopsAseEnviroment.ps1](AzureResourceGroup/DevOpsAse/pre-requisites/PrepareDevopsAseEnvironment.ps1) will handle the SSL certificate setup for the ILB and auto populate some of the parameters that are required by the deployment.
