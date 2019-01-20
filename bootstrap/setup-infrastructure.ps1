param(
    # The name of the project being deployed
    [Parameter(Mandatory)]
    [ParameterType]
    $ProjectName,
    # Environment being deployed
    [Parameter()]
    [string]
    $Environment,
    # Location of assets being deployed
    [Parameter()]
    [String]
    $Location
)

Install-Module Az -Force
Import-Module Az, Az.KeyVault

$ClientId = $env:AZURE_CLIENT_ID
$ClientSecret = ConvertTo-SecureString -String $env:AZURE_CLIENT_SECRET -AsPlainText -Force
$TenantId = $env:AZURE_TENANT_ID
$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID

$Credential = [pscredential]::new($ClientId, $ClientSecret)

Login-AzureRmAccount -Credential $Credential -ServicePrincipal -TenantId $TenantId -SubscriptionId $SubscriptionId

if ($Environment.Length -eq 0) {
    $Environment == "dev"
}

if($Location.Length -eq 0) {
    $Location = "eastus2"
}

$rg = $(Get-AzResourceGroup -Name $ProjectName-$Environment)
$storage_account
$storage_container
$key_vault
$service_principal = Get-AzADServicePrincipal -ServicePrincipalName $ClientId
[string[]]$certPermissions = @('Get','List','Delete','Create','Import','Update','managecontacts','manageissuers','getissuers','listissuers','setissuers','deleteissuers','recover','backup','restore','purge')
[string[]]$storagePermissions = @('get','list','delete','set','update','regeneratekey','getsas','listsas','deletesas','setsas','recover','backup','restore','purge')
[string[]]$secretsPermissions = @('get','list','set','delete','backup','restore','recover','purge')
[string[]]$keyPermissions = @('decrypt','encrypt','unwrapKey','wrapKey','verify','sign','get','list','update','create','import','delete','backup','restore','recover','purge')

if(!$rg) {
    $rg = New-AzResourceGroup -Name $ProjectName-$Environment -Location $Location -Tag $Tags

    $storage_account = New-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName `
        -SkuName "Standard_LRS" `
        -Location $Location `
        -Kind StorageV2 `
        -AssignIdentity `
        -Tag $Tags `
        -Name $ProjectName$Environment `
        -EnableHierarchicalNamespace $true
    $storage_container = New-AzStorageContainer -Name "state"
    $key_vault = Setup-KeyVault -ResourceGroup $rg
}
else {
    $rg = Get-AzResourceGroup -Name $ProjectName-$Environment
    $storage_account = Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $ProjectName$Environment
    $key_vault = Get-AzKeyVault -VaultName $ProjectName$Environment -ResourceGroupName $rg.ResourceGroupName

    if($storage_account){
        try {
            $storage_container = Get-AzStorageContainer -Name "state"
        }
        catch {
            $storage_container = New-AzStorageContainer -Name "state"
        }
    }

    if(!$key_vault){
        Setup-KeyVault -ResourceGroup $rg
    }
    
}


function Setup-KeyVault {
    param (
        # Resource Group
        [Parameter(AttributeValues)]
        [PSResourceGroup]
        $ResourceGroup
    )
    
    $key_vault = New-AzKeyVault -Name $ProjectName$Environment `
    -ResourceGroupName $rg.ResourceGroupName `
    -EnabledForDeployment `
    -EnabledForDiskEncryption `
    -Location $rg.Location

    # Add Storage Account to Key Vault
    Set-AzKeyVaultAccessPolicy -VaultName $key_vault.VaultName `
        -EmailAddress "ian.cornett@outlook.com" `
        -PermissionsToCertificates  $certPermissions`
        -PermissionsToStorage $storagePermissions `
        -PermissionsToSecrets $secretsPermissions `
        -PermissionsToKeys $keyPermissions
    Set-AzKeyVaultAccessPolicy -VaultName $key_vault.VaultName `
        -ServicePrincipalName $service_principal.ServicePrincipalName `
        -PermissionsToCertificates $certPermissions `
        -PermissionsToKeys $keyPermissions `
        -PermissionsToSecrets $secretsPermissions `
        -PermissionsToStorage $storagePermissions
    Add-AzKeyVaultManagedStorageAccount -VaultName $key_vault.VaultName -AccountName $storage_account.StorageAccountName -AccountResourceId $storage_account.Id
    return $key_vault
}