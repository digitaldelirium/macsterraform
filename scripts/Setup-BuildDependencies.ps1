param (
    # Name of Storage Account for state storage
    [Parameter(Mandatory, 
        HelpMessage='Name of Storage Account for state storage (no dashes or underscores allowed)')]
    [ValidateNotNullOrEmpty]
    [string]
    $StorageAccountName,
    # Storage Container Name for state assets
    [Parameter(Mandatory,
        HelpMessage='The Azure Storage Container to store state assets')]
    [ValidateNotNullOrEmpty]        
    [string]
    $StorageContainerName,
    # Storage Key name for state file
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]    
    [string]
    $StorageKeyName,
    # Azure Datacenter where storage account will be located
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]
    [String]
    $Location,
    # Name of the Azure Resource Group for your Storage Account
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]
    [string]
    $ResourceGroupName,
    # Run as Service Principal
    [ParameterSet("SPN")]
    [SwitchParameter]
    $ServicePrincipal,
    # Service Principal Running Account
    [ParameterSet("SPN")]
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]
    [string]
    $UserName,
    # Service Principal Secret
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]
    [string]
    $ClientSecret
)

try {
    Import-Module -Name Az
}
catch {
    Write-Warning -Message 'Could not import Azure PowerShell module, attempting to install it to current user scope'
    try {
        Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
    }
    catch {
        Write-Error -Message 'Could not install the Azure PowerShell Module to Current User scope... Exiting'
        break
    }
}

Import-Module -Name Az, Az.Storage, Az.Resources

[pscredential]$credential
$account = $null

try {
    if ($ServicePrincipal) {
        $encryptedSecret = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
        $credential = [pscredential]::new($UserName, $encryptedSecret)
        $account = Connect-AzAccount -Credential $credential -ServicePrincipal -Tenant $tenantId
    }
}
catch {
    Write-Error -Message 'Could not login using Service Principal'
    break;
}
finally {
    Write-Error -Message 'Unable to login, the script must exit'
}

if ($account -eq $null) {
    $account = Connect-AzAccount
}

Write-Host "Working in Region:`t$Location"

try {
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
catch {
    Write-Warning -Message "The Resource Group $ResourceGroupName did not exist...  Creating"
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

try {
    $StorageAccount = Get-AzStorageAccount -Name $StorageAccountName | Set-AzStorageAccount
}
catch {
    Write-Warning -Message 'Azure Storage account does not exist, creating...'
    try {
        $StorageAccount = New-AzStorageAccount -Name $StorageAccountName -Location $Location -ResourceGroupName $ResourceGroup.ResourceGroupName `
        | Set-AzStorageAccount
    }
    catch {
        Write-Error -Message 'Could not create Storage Account...'
        Write-Error -Exception $_.Exception
        break
    }
}

$accessKey = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $StorageAccountName

try {
    $StorageContainer = Get-AzStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context
}
catch {
    Write-Warning -Message 'Azure Container does not exist, attempting to create it'
    try {
        $StorageContainer = New-AzStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context
    }
    catch {
        Write-Error -Message 'Could not create Storage Container...  Aborting'
        Write-Error -Exception $_.Exception
        break
    }
}

Write-Host 'Create Backend file and add to .gitignore'

$config = @"
access_key = $($accessKey.Value[0])
storage_account_name = $StorageAccount.Name
container_name = $StorageAccountContainer.Name
storage_account_key = $StorageAccountKey
"@