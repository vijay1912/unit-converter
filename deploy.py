#!/usr/bin/env python3
"""
Unit Converter EKS Deployment Script (Python)
Deploy the Unit Converter application to EKS without Helm

Usage:
    python3 deploy.py --image-uri YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest
    python3 deploy.py --wait-time 300
"""

import argparse
import subprocess
import sys
import time
import json
from pathlib import Path
from typing import Optional, Tuple
from datetime import datetime

class Colors:
    """ANSI color codes"""
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_info(message: str):
    """Print info message"""
    print(f"{Colors.BLUE}[INFO]{Colors.ENDC} {message}")

def print_success(message: str):
    """Print success message"""
    print(f"{Colors.GREEN}[SUCCESS]{Colors.ENDC} {message}")

def print_warning(message: str):
    """Print warning message"""
    print(f"{Colors.YELLOW}[WARNING]{Colors.ENDC} {message}")

def print_error(message: str):
    """Print error message"""
    print(f"{Colors.RED}[ERROR]{Colors.ENDC} {message}")

def run_command(command: list, description: str = "", check: bool = True) -> Tuple[bool, str]:
    """
    Run a shell command and return success status and output

    Args:
        command: Command to run as list
        description: Description of what the command does
        check: Raise exception on non-zero exit code

    Returns:
        Tuple of (success: bool, output: str)
    """
    try:
        if description:
            print_info(f"Executing: {description}")

        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode != 0:
            if check:
                print_error(f"Command failed: {' '.join(command)}")
                if result.stderr:
                    print_error(f"Error: {result.stderr}")
                return False, result.stderr
            return False, result.stderr

        return True, result.stdout.strip()

    except Exception as e:
        print_error(f"Failed to run command: {str(e)}")
        return False, str(e)

def check_prerequisites() -> bool:
    """Check if required tools are installed"""
    print_info("Checking prerequisites...")

    tools = ["kubectl", "aws"]
    missing_tools = []

    for tool in tools:
        success, _ = run_command(
            ["which", tool] if sys.platform != "win32" else ["where", tool],
            check=False
        )
        if not success:
            missing_tools.append(tool)

    if missing_tools:
        print_error(f"Missing required tools: {', '.join(missing_tools)}")
        return False

    print_success("All prerequisites satisfied")
    return True

def verify_cluster_connection() -> bool:
    """Verify connection to EKS cluster"""
    print_info("Verifying EKS cluster connection...")

    success, output = run_command(
        ["kubectl", "cluster-info"],
        description="Getting cluster info",
        check=False
    )

    if not success:
        print_error("Failed to connect to EKS cluster")
        return False

    print_success("Connected to EKS cluster")
    return True

def create_namespace(namespace: str) -> bool:
    """Create Kubernetes namespace"""
    print_info(f"Creating namespace: {namespace}")

    # Check if namespace exists
    success, _ = run_command(
        ["kubectl", "get", "namespace", namespace],
        check=False
    )

    if success:
        print_warning(f"Namespace {namespace} already exists")
        return True

    success, _ = run_command(
        ["kubectl", "create", "namespace", namespace],
        description=f"Creating namespace {namespace}"
    )

    if success:
        print_success(f"Namespace {namespace} created")

    return success

def deploy_manifests(manifest_dir: str, namespace: str) -> bool:
    """Deploy all Kubernetes manifests"""
    print_info("Deploying Kubernetes manifests...")

    manifest_path = Path(manifest_dir)
    if not manifest_path.exists():
        print_error(f"Manifest directory not found: {manifest_dir}")
        return False

    manifests = [
        "namespace.yaml",
        "serviceaccount.yaml",
        "role.yaml",
        "rolebinding.yaml",
        "configmap.yaml",
        "deployment.yaml",
        "service.yaml",
        "hpa.yaml",
        "pdb.yaml"
    ]

    for manifest in manifests:
        manifest_file = manifest_path / manifest
        if not manifest_file.exists():
            print_error(f"Manifest file not found: {manifest_file}")
            return False

        success, _ = run_command(
            ["kubectl", "apply", "-f", str(manifest_file)],
            description=f"Applying {manifest}"
        )

        if not success:
            return False

    print_success("All manifests deployed")
    return True

def wait_for_deployment(namespace: str, deployment: str, timeout: int = 300) -> bool:
    """Wait for deployment to reach ready state"""
    print_info(f"Waiting for deployment {deployment} to be ready (timeout: {timeout}s)...")

    start_time = time.time()
    check_interval = 10

    while time.time() - start_time < timeout:
        success, output = run_command(
            ["kubectl", "get", "deployment", deployment, "-n", namespace, "-o", "json"],
            check=False
        )

        if success:
            try:
                data = json.loads(output)
                ready_replicas = data.get("status", {}).get("readyReplicas", 0)
                desired_replicas = data.get("spec", {}).get("replicas", 0)

                elapsed = int(time.time() - start_time)
                print_info(f"Ready replicas: {ready_replicas}/{desired_replicas} (elapsed: {elapsed}s)")

                if ready_replicas == desired_replicas and desired_replicas > 0:
                    print_success("Deployment is ready")
                    return True
            except json.JSONDecodeError:
                pass

        time.sleep(check_interval)

    print_warning("Deployment did not reach ready state within timeout")
    return False

def get_service_endpoint(namespace: str, service: str, timeout: int = 300) -> Optional[str]:
    """Get LoadBalancer endpoint"""
    print_info(f"Retrieving service endpoint for {service}...")

    start_time = time.time()
    check_interval = 10

    while time.time() - start_time < timeout:
        success, output = run_command(
            ["kubectl", "get", "service", service, "-n", namespace, "-o", "json"],
            check=False
        )

        if success:
            try:
                data = json.loads(output)
                ingress = data.get("status", {}).get("loadBalancer", {}).get("ingress", [])

                if ingress:
                    endpoint = ingress[0].get("hostname") or ingress[0].get("ip")
                    if endpoint:
                        print_success(f"Service endpoint: http://{endpoint}")
                        return endpoint
            except json.JSONDecodeError:
                pass

        elapsed = int(time.time() - start_time)
        print_info(f"Waiting for LoadBalancer endpoint... ({elapsed}s)")
        time.sleep(check_interval)

    print_warning("LoadBalancer endpoint not yet available")
    print_info("You can check the endpoint later with:")
    print_info(f"  kubectl get service -n {namespace}")
    return None

def show_deployment_info(namespace: str, deployment: str, service: str):
    """Display deployment information"""
    print("\n" + "="*60)
    print(f"{Colors.BOLD}Deployment Information{Colors.ENDC}")
    print("="*60)
    print(f"Namespace:  {namespace}")
    print(f"Deployment: {deployment}")
    print(f"Service:    {service}")
    print("\n" + "="*60)
    print(f"{Colors.BOLD}Useful Commands{Colors.ENDC}")
    print("="*60)

    commands = [
        ("View deployment status", f"kubectl get deployment -n {namespace}"),
        ("View pods", f"kubectl get pods -n {namespace}"),
        ("View service", f"kubectl get service -n {namespace}"),
        ("View logs", f"kubectl logs -n {namespace} -l app=unit-converter -f"),
        ("View HPA status", f"kubectl get hpa -n {namespace}"),
        ("Describe deployment", f"kubectl describe deployment {deployment} -n {namespace}"),
    ]

    for desc, cmd in commands:
        print(f"\n{desc}:")
        print(f"  {cmd}")

def update_deployment_image(namespace: str, deployment: str, container: str, image: str) -> bool:
    """Update deployment container image"""
    print_info(f"Updating deployment image to: {image}")

    success, _ = run_command(
        ["kubectl", "set", "image", f"deployment/{deployment}",
         f"{container}={image}", "-n", namespace],
        description="Updating deployment image"
    )

    if not success:
        return False

    print_success("Deployment image updated")
    return True

def main():
    """Main deployment function"""
    parser = argparse.ArgumentParser(
        description="Deploy Unit Converter to EKS",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 deploy.py --image-uri YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest
  python3 deploy.py --image-uri YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest --wait-time 600
        """
    )

    parser.add_argument(
        "--image-uri",
        help="Container image URI",
        required=True
    )
    parser.add_argument(
        "--deployment",
        help="Deployment name",
        default="unit-converter-app"
    )
    parser.add_argument(
        "--service",
        help="Service name",
        default="unit-converter-service"
    )
    parser.add_argument(
        "--manifest-dir",
        help="Directory containing manifests",
        default="./k8s"
    )
    parser.add_argument(
        "--wait-time",
        type=int,
        help="Maximum wait time in seconds",
        default=300
    )
    parser.add_argument(
        "--no-wait",
        action="store_true",
        help="Don't wait for deployment to complete"
    )

    args = parser.parse_args()
    namespace = "unit-converter"

    # Print header
    print("\n" + "="*60)
    print(f"{Colors.BOLD}{Colors.BLUE}Unit Converter EKS Deployment{Colors.ENDC}")
    print("="*60 + "\n")

    # Check prerequisites
    if not check_prerequisites():
        sys.exit(1)

    # Verify cluster connection
    if not verify_cluster_connection():
        sys.exit(1)

    # Create namespace
    if not create_namespace(namespace):
        sys.exit(1)

    # Deploy manifests
    if not deploy_manifests(args.manifest_dir, namespace):
        sys.exit(1)

    # Replace the placeholder image before waiting for readiness.
    if not update_deployment_image(
        namespace, args.deployment, "unit-converter", args.image_uri
    ):
        sys.exit(1)

    # Wait for deployment
    if not args.no_wait:
        if not wait_for_deployment(namespace, args.deployment, args.wait_time):
            print_error("Deployment did not become ready")
            sys.exit(1)

        # Get service endpoint
        get_service_endpoint(namespace, args.service, args.wait_time)

    # Show deployment info
    show_deployment_info(namespace, args.deployment, args.service)

    print("\n" + "="*60)
    print(f"{Colors.GREEN}{Colors.BOLD}✓ Deployment completed successfully!{Colors.ENDC}")
    print("="*60 + "\n")

if __name__ == "__main__":
    main()
