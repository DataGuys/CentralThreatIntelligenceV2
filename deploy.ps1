# Deploy.ps1
# Script to deploy Bicep templates from GitHub raw URLs

#Requires -Modules Az

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GithubRepoBaseUrl = "https://raw.githubusercontent.com/YourUsername/YourRepo/main",
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupLocation = "eastus",
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "dev",
    
    [Parameter(Mandatory = $false)]
    [string]$Prefix = "demo",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        "environment" = $EnvironmentName
        "deployedBy" = "PowerShell"
        "deploymentDate" = (Get-Date -Format "yyyy-MM-dd")
    }
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to check if module is installed and import it
function EnsureModuleIsInstalled {
    param (
        [string]$ModuleName
    )
    
    if (-not (Get-Module -Name $ModuleName -ListAvailable)) {
        Write-Host "Module $ModuleName is not installed. Installing it now..."
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber
    }
    
    Import-Module -Name $ModuleName -Force
}

# Function to check if logged in to Azure
function EnsureAzureLoggedIn {
    try {
        $context = Get-AzContext
        if (-not $context.Account) {
            Write-Host "Not logged in to Azure. Connecting..."
            Connect-AzAccount
        }
        else {
            Write-Host "Already logged in as $($context.Account.Id) on subscription '$($context.Subscription.Name)'"
        }
    }
    catch {
        Write-Host "Error checking Azure login: $_"
        Write-Host "Attempting to connect..."
        Connect-AzAccount
    }
}

# Function to download files from GitHub
function DownloadFromGithub {
    param (
        [string]$BaseUrl,
        [string]$FilePath,
        [string]$OutputPath
    )
    
    $fullUrl = "$BaseUrl/$FilePath"
    $outputDirectory = Split-Path -Path $OutputPath -Parent
    
    # Create directory if it doesn't exist
    if (-not (Test-Path -Path $outputDirectory)) {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    }
    
    Write-Host "Downloading $fullUrl to $OutputPath..."
    
    try {
        Invoke-WebRequest -Uri $fullUrl -OutFile $OutputPath -UseBasicParsing
        if (Test-Path -Path $OutputPath) {
            Write-Host "Successfully downloaded $FilePath"
            return $true
        }
    }
    catch {
        Write-Host "Error downloading file $FilePath from $fullUrl : $_"
        return $false
    }
}

# Main script starts here
Write-Host "Starting Bicep deployment script..." -ForegroundColor Green

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
EnsureModuleIsInstalled -ModuleName "Az"
EnsureAzureLoggedIn

# Set up temporary directory for downloaded files
$tempDir = Join-Path -Path $env:TEMP -ChildPath "BicepDeploy_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
Write-Host "Using temporary directory: $tempDir"

# Download files from GitHub
Write-Host "Downloading Bicep files from GitHub..." -ForegroundColor Yellow
$mainBicepPath = Join-Path -Path $tempDir -ChildPath "main.bicep"
$modulesDirPath = Join-Path -Path $tempDir -ChildPath "modules"
$resourcesBicepPath = Join-Path -Path $modulesDirPath -ChildPath "resources.bicep"

# Download main.bicep
if (-not (DownloadFromGithub -BaseUrl $GithubRepoBaseUrl -FilePath "main.bicep" -OutputPath $mainBicepPath)) {
    Write-Error "Failed to download main.bicep. Exiting."
    exit 1
}

# Download resources.bicep
if (-not (DownloadFromGithub -BaseUrl $GithubRepoBaseUrl -FilePath "modules/resources.bicep" -OutputPath $resourcesBicepPath)) {
    Write-Error "Failed to download resources.bicep. Exiting."
    exit 1
}

# Verify files exist
if (-not (Test-Path -Path $mainBicepPath) -or -not (Test-Path -Path $resourcesBicepPath)) {
    Write-Error "Required Bicep files not found in temporary directory. Exiting."
    exit 1
}

# Prepare parameters for deployment
$deploymentName = "BicepDeployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
$deploymentParams = @{
    Name                  = $deploymentName
    Location              = $ResourceGroupLocation
    TemplateFile          = $mainBicepPath
    TemplateParameterObject = @{
        location          = $ResourceGroupLocation
        prefix            = $Prefix
        environmentName   = $EnvironmentName
        tags              = $Tags
    }
    Verbose               = $true
}

# Deploy the Bicep template at subscription level
try {
    Write-Host "Starting deployment of Bicep template at subscription scope..." -ForegroundColor Yellow
    $deployment = New-AzSubscriptionDeployment @deploymentParams
    
    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "Deployment name: $deploymentName"
        Write-Host "Resource Group: $($deployment.Outputs.resourceGroupName.Value)"
        Write-Host "Log Analytics Workspace ID: $($deployment.Outputs.logAnalyticsWorkspaceId.Value)"
        Write-Host "Key Vault ID: $($deployment.Outputs.keyVaultId.Value)"
        Write-Host "DCR Syslog ID: $($deployment.Outputs.dcRuleSyslogId.Value)"
        Write-Host "DCR CEF ID: $($deployment.Outputs.dcRuleCEFId.Value)"
        Write-Host "Query Pack ID: $($deployment.Outputs.queryPackId.Value)"
    }
    else {
        Write-Error "Deployment failed with state: $($deployment.ProvisioningState)"
    }
}
catch {
    Write-Error "Error during deployment: $_"
    exit 1
}

# Clean up temporary files
try {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Host "Cleanup completed." -ForegroundColor Green
}
catch {
    Write-Warning "Failed to clean up temporary files: $_"
}

Write-Host "Script execution completed." -ForegroundColor Green
