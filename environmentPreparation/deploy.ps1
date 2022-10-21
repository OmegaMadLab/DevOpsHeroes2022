Login-AzAccount

$location = "westus"

# Get the RG where the bicep container registry resides
$brRgName = "BicepRegistry-Demo-RG"
$brRg = Get-AzResourceGroup -Name $brRgName

# Create RGs for DEV and PROD env
$devRg = New-AzResourceGroup -Name 'App1-TEST-RG' -location $location
$prodRg = New-AzResourceGroup -Name 'App1-PROD-RG' -location $location

# Create a role for validating ARM deployment
$role = Get-AzRoleDefinition -Name "Deployment validator" -ErrorAction SilentlyContinue

if (-not $role) {
    $role = Get-AzRoleDefinition | Select-Object -First 1

    $role.Id = $null
    $role.Name = "Deployment validator"
    $role.Description = "Can validate an ARM deployment."
    $role.Actions.RemoveRange(0,$role.Actions.Count)
    $role.Actions.Add("Microsoft.Resources/deployments/validate/action")
    $role.NotActions.RemoveRange(0,$role.NotActions.Count)
    $role.AssignableScopes.Add("/subscriptions/$((Get-AzContext).Subscription.Id)")

    New-AzRoleDefinition -Role $role
}

# Create a service principal and grant it contributor access on the DEV rg
$azureContext = Get-AzContext
$servicePrincipal = New-AzADServicePrincipal `
    -DisplayName "DevOpsHeroes2022_DEV" `
    -Role "Contributor" `
    -Scope $devRg.ResourceId

# Assign also the Contributor role on the RG hosting the bicep registry
New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $brRg.ResourceGroupName `
    -RoleDefinitionName "Contributor"

# Assign also the Deployment validator role on PROD RG
New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $prodRg.ResourceGroupName `
    -RoleDefinitionName "Deployment validator"

$output = @{
   clientId = $($servicePrincipal.AppId)
   clientSecret = $servicePrincipal.PasswordCredentials[0].SecretText
   subscriptionId = $($azureContext.Subscription.Id)
   tenantId = $($azureContext.Tenant.Id)
}

$output | ConvertTo-Json
$output | ConvertTo-Json | Set-Clipboard
# Paste the content of the clipboard in a new GitHub secret called AzCred_DEV

# Create a service principal and grant it access on the PROD rg
$servicePrincipal = New-AzADServicePrincipal `
    -DisplayName "DevOpsHeroes2022_PROD" `
    -Role "Contributor" `
    -Scope $prodRg.ResourceId

# Assign also the Contributor role on the RG hosting the bicep registry
New-AzRoleAssignment -ApplicationId $servicePrincipal.AppId `
    -ResourceGroupName $brRg.ResourceGroupName `
    -RoleDefinitionName "Contributor"

$output = @{
   clientId = $($servicePrincipal.AppId)
   clientSecret = $servicePrincipal.PasswordCredentials[0].SecretText
   subscriptionId = $($azureContext.Subscription.Id)
   tenantId = $($azureContext.Tenant.Id)
}

$output | ConvertTo-Json
$output | ConvertTo-Json | Set-Clipboard
# Paste the content of the clipboard in a new GitHub secret called AzCred_PROD
