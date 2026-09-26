#!/bin/bash

# Unit Converter EKS Deployment Script
# This script deploys the Unit Converter application to EKS without Helm

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="unit-converter"
DEPLOYMENT_NAME="unit-converter-app"
SERVICE_NAME="unit-converter-service"
KUBE_MANIFEST_DIR="./k8s"

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

verify_cluster_connection() {
    print_info "Verifying EKS cluster connection..."
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to EKS cluster"
    else
        print_error "Failed to connect to EKS cluster"
        exit 1
    fi
}

create_namespace() {
    print_info "Creating namespace: $NAMESPACE"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace $NAMESPACE created"
    fi
}

deploy_manifests() {
    print_info "Deploying Kubernetes manifests..."
    
    if [ ! -d "$KUBE_MANIFEST_DIR" ]; then
        print_error "Kubernetes manifests directory not found: $KUBE_MANIFEST_DIR"
        exit 1
    fi
    
    # Apply manifests in order
    print_info "Applying namespace manifest..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/namespace.yaml"
    
    print_info "Applying ServiceAccount and RBAC manifests..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/serviceaccount.yaml"
    kubectl apply -f "$KUBE_MANIFEST_DIR/role.yaml"
    kubectl apply -f "$KUBE_MANIFEST_DIR/rolebinding.yaml"
    
    print_info "Applying ConfigMap..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/configmap.yaml"
    
    print_info "Applying Deployment..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/deployment.yaml"
    
    print_info "Applying Service..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/service.yaml"
    
    print_info "Applying HorizontalPodAutoscaler..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/hpa.yaml"
    
    print_info "Applying PodDisruptionBudget..."
    kubectl apply -f "$KUBE_MANIFEST_DIR/pdb.yaml"
    
    print_success "All manifests deployed successfully"
}

wait_for_deployment() {
    print_info "Waiting for deployment to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        ready_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        desired_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        print_info "Ready replicas: $ready_replicas/$desired_replicas (attempt $attempt/$max_attempts)"
        
        if [ "$ready_replicas" = "$desired_replicas" ] && [ "$desired_replicas" != "0" ]; then
            print_success "Deployment is ready"
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    print_warning "Deployment did not reach ready state within timeout"
    return 1
}

get_service_endpoint() {
    print_info "Retrieving service endpoint..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        endpoint=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        
        if [ -n "$endpoint" ]; then
            print_success "Service endpoint: http://$endpoint"
            return 0
        fi
        
        print_info "Waiting for LoadBalancer endpoint... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_warning "LoadBalancer endpoint not yet available"
    print_info "You can check the endpoint later with:"
    print_info "  kubectl get service -n $NAMESPACE"
    return 1
}

show_deployment_info() {
    print_info "=== Deployment Information ==="
    print_info "Namespace: $NAMESPACE"
    print_info "Deployment: $DEPLOYMENT_NAME"
    print_info "Service: $SERVICE_NAME"
    print_info ""
    print_info "=== Useful Commands ==="
    print_info "View deployment status:"
    print_info "  kubectl get deployment -n $NAMESPACE"
    print_info ""
    print_info "View pods:"
    print_info "  kubectl get pods -n $NAMESPACE"
    print_info ""
    print_info "View service:"
    print_info "  kubectl get service -n $NAMESPACE"
    print_info ""
    print_info "View logs:"
    print_info "  kubectl logs -n $NAMESPACE -l app=unit-converter -f"
    print_info ""
    print_info "View HPA status:"
    print_info "  kubectl get hpa -n $NAMESPACE"
    print_info ""
    print_info "Describe deployment:"
    print_info "  kubectl describe deployment $DEPLOYMENT_NAME -n $NAMESPACE"
}

update_deployment_image() {
    local image_uri=$1
    
    if [ -z "$image_uri" ]; then
        print_error "Image URI is required"
        return 1
    fi
    
    print_info "Updating deployment image to: $image_uri"
    
    kubectl set image deployment/$DEPLOYMENT_NAME \
        unit-converter=$image_uri \
        -n $NAMESPACE \
        --record
    
    print_success "Deployment image updated"
    print_info "Waiting for rollout to complete..."
    
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE
    print_success "Rollout completed"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Unit Converter EKS Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check if image URI is provided as argument
    if [ $# -gt 0 ]; then
        print_info "Image URI provided: $1"
        IMAGE_URI=$1
    fi
    
    check_prerequisites
    verify_cluster_connection
    create_namespace
    deploy_manifests
    wait_for_deployment
    get_service_endpoint
    show_deployment_info
    
    # If image URI was provided, update the deployment
    if [ -n "$IMAGE_URI" ]; then
        echo ""
        update_deployment_image "$IMAGE_URI"
    fi
    
    echo ""
    print_success "Deployment completed successfully!"
}

# Run main function
main "$@"
