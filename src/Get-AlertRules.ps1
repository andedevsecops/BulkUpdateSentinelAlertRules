PARAM (
    [Parameter(Mandatory=$true)]$ResourceGroup,
    [Parameter(Mandatory=$true)]$Workspace,   
	[Parameter(Mandatory=$true)]$ClientID,
    [Parameter(Mandatory=$true)]$ClientSecret,
	[Parameter(Mandatory=$true)]$DomainName,
	[Parameter(Mandatory=$true)]$TenantGUID,
)

$loginURL = "https://login.microsoftonline.com/"
$tenantdomain = "$DomainName.onmicrosoft.com"
$resource = "https://management.azure.com"
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body
$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"} 

function CheckModules($module) {
    $installedModule = Get-InstalledModule -Name $module -ErrorAction SilentlyContinue
    if ($null -eq $installedModule) {
        Write-Warning "The $module PowerShell module is not found"
        #check for Admin Privleges
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

        if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
            #Not an Admin, install to current user
            Write-Warning -Message "Can not install the $module module. You are not running as Administrator"
            Write-Warning -Message "Installing $module module to current user Scope"
            Install-Module -Name $module -Scope CurrentUser -Force
            Import-Module -Name $module -Force
        }
        else {
            #Admin, install to all users
            Write-Warning -Message "Installing the $module module to all users"
            Install-Module -Name $module -Force
            Import-Module -Name $module -Force
        }
    }
    #Install-Module will obtain the module from the gallery and install it on your local machine, making it available for use.
    #Import-Module will bring the module and its functions into your current powershell session, if the module is installed.  
}


CheckModules("Az.Resources")
CheckModules("Az.OperationalInsights")
CheckModules("Az.SecurityInsights")
CheckModules("Az.MonitoringSolutions")

Write-Host "`r`nIf not logged in to Azure already, you will now be asked to log in to your Azure environment. `nFor this script to work correctly, you need to provide credentials of a Global Admin or Security Admin for your organization. `nThis will allow the script to enable all required connectors.`r`n" -BackgroundColor Magenta

Read-Host -Prompt "Press enter to continue or CTRL+C to quit the script" 

$context = Get-AzContext

if(!$context){
    Connect-AzAccount
    $context = Get-AzContext
}

$SubscriptionId = $context.Subscription.Id

$alertRules = Invoke-WebRequest -Method GET -Headers $headerParams -Uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/${ResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${Workspace}/providers/Microsoft.SecurityInsights/alertRules?api-version=2020-01-01"

$alertRules = $alertRules.content | ConvertFrom-Json

foreach ($alertRule in $alertRules.value){
    if ($alertRule.properties.displayName.StartsWith("(AUTO DISABLED)"))
    {     
        $alertBody = @{}
		$alertBody | Add-Member -NotePropertyName kind -NotePropertyValue $alertRule.kind -Force
        $alertBody | Add-Member -NotePropertyName etag -NotePropertyValue $alertRule.etag -Force		
        
		$props = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        IF ($alertRule.kind -eq "MicrosoftSecurityIncidentCreation") {
		$alertDisplayName = $alertRule.properties.displayName.Replace("(AUTO DISABLED)","")
        $props.Add("productFilter", $alertRule.properties.productFilter)
        $props.Add("displayName", $alertDisplayName)
        $props.Add("enabled", $true)
        }
        else {
            $props.Add("productFilter", $alertRule.properties.productFilter)
            $props.Add("alertRuleTemplateName", $alertRule.properties.alertRuleTemplateName)
            $props.Add("enabled", $true)
        }
        $alertBody | Add-Member -NotePropertyName properties -NotePropertyValue $props		    
        
        $alertBody = ($alertBody | ConvertTo-Json -Depth 3)        
        
        $ruleId = $alertRule.name
        $UpdateAlertUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/${ResourceGroup}/providers/Microsoft.OperationalInsights/workspaces/${Workspace}/providers/Microsoft.SecurityInsights/alertRules/${ruleId}?api-version=2020-01-01"
        
        
        $result = Invoke-WebRequest -Method PUT -Headers $headerParams -Uri $UpdateAlertUri -Body $alertBody -ContentType application/json

        Write-Host $result.StatusCode
    }
}