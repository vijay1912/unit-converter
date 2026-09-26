#!/usr/bin/env pwsh

# Unit Converter EKS Deployment Script (PowerShell)
# This script deploys the Unit Converter application to EKS without Helm

param(
    [string]$ImageUri,
    [string]$Namespace = "unit-converter",
    [string]$DeploymentName = "unit-converter-app",
    [string]$ServiceName = "unit-converter-service",
    [string]$ManifestDir = "./k8s"
)

# Configuration
$ErrorActionPreference = "Stop"

# Color codes
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $ColorInfo
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $ColorSuccess
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $ColorWarning
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $ColorError
}

function Check-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    try {
        $null = kubectl version --client
        Write-Success "kubectl is available"
    } catch {
        Write-Error-Custom "kubectl is not installed or not in PATH"
        exit 1
    }
    
    try {
        $null = aws --version
        Write-Success "AWS CLI is available"
    } catch {
        Write-Error-Custom "AWS CLI is not installed or not in PATH"
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

function Verify-ClusterConnection {
    Write-Info "Verifying EKS cluster connection..."
    
    try {
        $null = kubectl cluster-info
        Write-Success "Connected to EKS cluster"
    } catch {
        Write-Error-Custom "Failed to connect to EKS cluster"
        exit 1
    }
}

function Create-Namespace {
    Write-Info "Creating namespace: $Namespace"
    
    try {
        $null = kubectl get namespace $Namespace 2>$null
        Write-Warning "Namespace $Namespace already exists"
    } catch {
        kubectl create namespace $Namespace
        Write-Success "Namespace $Namespace created"
    }
}

function Deploy-Manifests {
    Write-Info "Deploying Kubernetes manifests..."
    
    if (-not (Test-Path $ManifestDir)) {
        Write-Error-Custom "Kubernetes manifests directory not found: $ManifestDir"
        exit 1
    }
    
    $manifestFiles = @(
        "namespace.yaml",
        "serviceaccount.yaml",
        "role.yaml",
        "rolebinding.yaml",
        "configmap.yaml",
        "deployment.yaml",
        "service.yaml",
        "hpa.yaml",
        "pdb.yaml"
    )
    
    foreach ($file in $manifestFiles) {
        $filePath = Join-Path $ManifestDir $file
        if (Test-Path $filePath) {
            Write-Info "Applying $file..."
            kubectl apply -f $filePath
        } else {
            Write-Warning "Manifest file not found: $filePath"
        }
    }
    
    Write-Success "All manifests deployed successfully"
}

function Wait-ForDeployment {
    Write-Info "Waiting for deployment to be ready..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            $deployment = kubectl get deployment $DeploymentName -n $Namespace -o json | ConvertFrom-Json
            $readyReplicas = $deployment.status.readyReplicas -as [int] ?? 0
            $desiredReplicas = $deployment.spec.replicas -as [int] ?? 0
            
            Write-Info "Ready replicas: $readyReplicas/$desiredReplicas (attempt $attempt/$maxAttempts)"
            
            if ($readyReplicas -eq $desiredReplicas -and $desiredReplicas -gt 0) {
                Write-Success "Deployment is ready"
                return $true
            }
        } catch {
            Write-Warning "Error checking deployment status: $_"
        }
        
        Start-Sleep -Seconds 10
        $attempt++
    }
    
    Write-Warning "Deployment did not reach ready state within timeout"
    return $false
}

function Get-ServiceEndpoint {
    Write-Info "Retrieving service endpoint..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            $service = kubectl get service $ServiceName -n $Namespace -o json 2>$null | ConvertFrom-Json
            $endpoint = $service.status.loadBalancer.ingress[0].hostname
            
            if (-not [string]::IsNullOrEmpty($endpoint)) {
                Write-Success "Service endpoint: http://$endpoint"
                return $endpoint
            }
        } catch {
            # Silently continue
        }
        
        Write-Info "Waiting for LoadBalancer endpoint... (attempt $attempt/$maxAttempts)"
        Start-Sleep -Seconds 10
        $attempt++
    }
    
    Write-Warning "LoadBalancer endpoint not yet available"
    Write-Info "You can check the endpoint later with:"
    Write-Info "  kubectl get service -n $Namespace"
    return $null
}

function Show-DeploymentInfo {
    Write-Info "========== Deployment Information =========="
    Write-Info "Namespace: $Namespace"
    Write-Info "Deployment: $DeploymentName"
    Write-Info "Service: $ServiceName"
    Write-Info ""
    Write-Info "========== Useful Commands =========="
    Write-Info "View deployment status:"
    Write-Info "  kubectl get deployment -n $Namespace"
    Write-Info ""
    Write-Info "View pods:"
    Write-Info "  kubectl get pods -n $Namespace"
    Write-Info ""
    Write-Info "View service:"
    Write-Info "  kubectl get service -n $Namespace"
    Write-Info ""
    Write-Info "View logs:"
    Write-Info "  kubectl logs -n $Namespace -l app=unit-converter -f"
    Write-Info ""
    Write-Info "View HPA status:"
    Write-Info "  kubectl get hpa -n $Namespace"
    Write-Info ""
    Write-Info "Describe deployment:"
    Write-Info "  kubectl describe deployment $DeploymentName -n $Namespace"
}

function Update-DeploymentImage {
    param([string]$ImageUri)
    
    if ([string]::IsNullOrEmpty($ImageUri)) {
        Write-Error-Custom "Image URI is required"
        return $false
    }
    
    Write-Info "Updating deployment image to: $ImageUri"
    
    kubectl set image deployment/$DeploymentName `
        unit-converter=$ImageUri `
        -n $Namespace `
        --record
    
    Write-Success "Deployment image updated"
    Write-Info "Waiting for rollout to complete..."
    
    kubectl rollout status deployment/$DeploymentName -n $Namespace
    Write-Success "Rollout completed"
    return $true
}

function Deploy-UnitConverter {
    param([string]$ImageUri)
    
    Write-Host "========================================"
    Write-Host "Unit Converter EKS Deployment" -ForegroundColor $ColorInfo
    Write-Host "========================================" 
    Write-Host ""
    
    if (-not [string]::IsNullOrEmpty($ImageUri)) {
        Write-Info "Image URI provided: $ImageUri"
    }
    
    Check-Prerequisites
    Verify-ClusterConnection
    Create-Namespace
    Deploy-Manifests
    Wait-ForDeployment
    Get-ServiceEndpoint
    Show-DeploymentInfo
    
    if (-not [string]::IsNullOrEmpty($ImageUri)) {
        Write-Host ""
        Update-DeploymentImage $ImageUri
    }
    
    Write-Host ""
    Write-Success "Deployment completed successfully!"
}

# Main execution
Deploy-UnitConverter -ImageUri $ImageUri
