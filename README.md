# Bulk Update Sentinel Analytical Rules
Update all the Azure Sentinel Analytical Rules

# Pre-requisites
Create the app in Azure Active Directory:

1.	Go to the Azure portal at https://portal.azure.com  
2.	From the menu, select Azure Active Directory  
3.	From the Azure Active Directory menu, select App registrations  
4.	From the top menu, select the New registration button  
5.	Enter the name for your app; for example "AzureSentinelApp"   
6.	For the type of supported account types  
	"Account in this organizational directory only"  
7.	In the Redirect URI field, in the dropdown, select Web, and in the URL field, enter http://localhost:3000  
8.	Confirm changes by selecting the Register button   
9.	Go to the API permissions blade  
10.	Click Add a permission to add the required API permissions:  
    Select the Microsoft API: Azure Service Management  
    Select the option to provide delegated permissions to Access Azure Service Management as organization users  

## Add a client secret

1.	In App registrations, select your application for example "AzureSentinelApp"  
2.	Select Certificates & secrets > New client secret  
3.	Add a description for your client secret  
4.	Select a duration  
5.	Select Add  
6.	Record the secret's value for use in your client application code. 

**Note**    
This secret value is never displayed again after you leave this page. Please save it  

## Add Azure AD App to Azure Resource Group

1. Go to the Azure Resource group, where you have your "Azure Sentinel and LA WorkSpace"  
2. Click on "Access Control (IAM)" --> Add --> Add role assignment  
3. Under "role" search "Azure Sentinel Contributor"  
4. Under "Assign Access to" --> select "User, group or Service Principal"  
5. Under "Select" search Azure AD App for example "AzureSentinelApp"  
6. Click on Save  

# Running PowerShell

1.	PowerShell scripts prompts to end the following params
	```
	[Parameter(Mandatory=$true)]$ResourceGroup, --> Name of the ResourceGroup your "Azure Sentinel and LA WorkSpace"
    [Parameter(Mandatory=$true)]$Workspace,   --> Azure LA WorkSpace Name
	[Parameter(Mandatory=$true)]$ClientID, --> AAD App ClientID
    [Parameter(Mandatory=$true)]$ClientSecret, --> AAD App ClientSecret
	[Parameter(Mandatory=$true)]$DomainName, --> Your Domain Name like "Contoso"
	[Parameter(Mandatory=$true)]$TenantGUID --> AAD App TenantGUID
	```