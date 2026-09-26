#!/usr/bin/env ruby
# Unit Converter EKS Deployment Script (Ruby)
# Deploy the Unit Converter application to EKS without Helm
#
# Usage:
#   ruby deploy.rb
#   ruby deploy.rb --image-uri YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/unit-converter:latest
#   ruby deploy.rb --namespace custom-namespace

require 'optparse'
require 'json'
require 'open3'
require 'time'

class Colors
  BLUE = "\033[94m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  RED = "\033[91m"
  ENDC = "\033[0m"
  BOLD = "\033[1m"
end

class UnitConverterDeployer
  def initialize(options = {})
    @namespace = options[:namespace] || "unit-converter"
    @deployment = options[:deployment] || "unit-converter-app"
    @service = options[:service] || "unit-converter-service"
    @manifest_dir = options[:manifest_dir] || "./k8s"
    @image_uri = options[:image_uri]
    @wait_time = options[:wait_time] || 300
    @no_wait = options[:no_wait] || false
  end

  def print_info(message)
    puts "#{Colors.BLUE}[INFO]#{Colors.ENDC} #{message}"
  end

  def print_success(message)
    puts "#{Colors.GREEN}[SUCCESS]#{Colors.ENDC} #{message}"
  end

  def print_warning(message)
    puts "#{Colors.YELLOW}[WARNING]#{Colors.ENDC} #{message}"
  end

  def print_error(message)
    puts "#{Colors.RED}[ERROR]#{Colors.ENDC} #{message}"
  end

  def run_command(command, description = "")
    print_info("Executing: #{description}") unless description.empty?
    
    stdout, stderr, status = Open3.capture3(*command)
    
    if !status.success?
      print_error("Command failed: #{command.join(' ')}")
      print_error("Error: #{stderr}") unless stderr.empty?
      return [false, stderr]
    end
    
    [true, stdout.strip]
  end

  def check_prerequisites
    print_info "Checking prerequisites..."
    
    tools = ["kubectl", "aws"]
    missing_tools = []
    
    tools.each do |tool|
      stdout, _, status = Open3.capture3("which", tool)
      missing_tools << tool unless status.success?
    end
    
    if !missing_tools.empty?
      print_error "Missing required tools: #{missing_tools.join(', ')}"
      return false
    end
    
    print_success "All prerequisites satisfied"
    true
  end

  def verify_cluster_connection
    print_info "Verifying EKS cluster connection..."
    
    success, output = run_command(["kubectl", "cluster-info"], "Getting cluster info")
    
    unless success
      print_error "Failed to connect to EKS cluster"
      return false
    end
    
    print_success "Connected to EKS cluster"
    true
  end

  def create_namespace
    print_info "Creating namespace: #{@namespace}"
    
    # Check if namespace exists
    _, _, status = Open3.capture3("kubectl", "get", "namespace", @namespace)
    
    if status.success?
      print_warning "Namespace #{@namespace} already exists"
      return true
    end
    
    success, _ = run_command(
      ["kubectl", "create", "namespace", @namespace],
      "Creating namespace #{@namespace}"
    )
    
    if success
      print_success "Namespace #{@namespace} created"
    end
    
    success
  end

  def deploy_manifests
    print_info "Deploying Kubernetes manifests..."
    
    manifest_path = File.expand_path(@manifest_dir)
    unless File.directory?(manifest_path)
      print_error "Manifest directory not found: #{manifest_path}"
      return false
    end
    
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
    
    manifests.each do |manifest|
      manifest_file = File.join(manifest_path, manifest)
      unless File.exist?(manifest_file)
        print_warning "Manifest file not found: #{manifest_file}"
        next
      end
      
      success, _ = run_command(
        ["kubectl", "apply", "-f", manifest_file],
        "Applying #{manifest}"
      )
      
      print_warning "Failed to apply #{manifest}, continuing..." unless success
    end
    
    print_success "All manifests deployed"
    true
  end

  def wait_for_deployment
    print_info "Waiting for deployment #{@deployment} to be ready (timeout: #{@wait_time}s)..."
    
    start_time = Time.now
    check_interval = 10
    
    while Time.now - start_time < @wait_time
      success, output = run_command(
        ["kubectl", "get", "deployment", @deployment, "-n", @namespace, "-o", "json"],
        ""
      )
      
      if success
        begin
          data = JSON.parse(output)
          ready_replicas = data.dig("status", "readyReplicas") || 0
          desired_replicas = data.dig("spec", "replicas") || 0
          elapsed = (Time.now - start_time).to_i
          
          print_info "Ready replicas: #{ready_replicas}/#{desired_replicas} (elapsed: #{elapsed}s)"
          
          if ready_replicas == desired_replicas && desired_replicas > 0
            print_success "Deployment is ready"
            return true
          end
        rescue JSON::ParserError
        end
      end
      
      sleep check_interval
    end
    
    print_warning "Deployment did not reach ready state within timeout"
    false
  end

  def get_service_endpoint
    print_info "Retrieving service endpoint for #{@service}..."
    
    start_time = Time.now
    check_interval = 10
    
    while Time.now - start_time < @wait_time
      success, output = run_command(
        ["kubectl", "get", "service", @service, "-n", @namespace, "-o", "json"],
        ""
      )
      
      if success
        begin
          data = JSON.parse(output)
          ingress = data.dig("status", "loadBalancer", "ingress") || []
          
          if !ingress.empty?
            endpoint = ingress[0]["hostname"] || ingress[0]["ip"]
            if endpoint
              print_success "Service endpoint: http://#{endpoint}"
              return endpoint
            end
          end
        rescue JSON::ParserError
        end
      end
      
      elapsed = (Time.now - start_time).to_i
      print_info "Waiting for LoadBalancer endpoint... (#{elapsed}s)"
      sleep check_interval
    end
    
    print_warning "LoadBalancer endpoint not yet available"
    print_info "You can check the endpoint later with:"
    print_info "  kubectl get service -n #{@namespace}"
    nil
  end

  def show_deployment_info
    puts "\n" + "="*60
    puts "#{Colors.BOLD}Deployment Information#{Colors.ENDC}"
    puts "="*60
    puts "Namespace:  #{@namespace}"
    puts "Deployment: #{@deployment}"
    puts "Service:    #{@service}"
    puts "\n" + "="*60
    puts "#{Colors.BOLD}Useful Commands#{Colors.ENDC}"
    puts "="*60
    
    commands = [
      ["View deployment status", "kubectl get deployment -n #{@namespace}"],
      ["View pods", "kubectl get pods -n #{@namespace}"],
      ["View service", "kubectl get service -n #{@namespace}"],
      ["View logs", "kubectl logs -n #{@namespace} -l app=unit-converter -f"],
      ["View HPA status", "kubectl get hpa -n #{@namespace}"],
      ["Describe deployment", "kubectl describe deployment #{@deployment} -n #{@namespace}"]
    ]
    
    commands.each do |desc, cmd|
      puts "\n#{desc}:"
      puts "  #{cmd}"
    end
  end

  def update_deployment_image
    print_info "Updating deployment image to: #{@image_uri}"
    
    success, _ = run_command(
      ["kubectl", "set", "image", "deployment/#{@deployment}", 
       "unit-converter=#{@image_uri}", "-n", @namespace, "--record"],
      "Updating deployment image"
    )
    
    return false unless success
    
    print_info "Waiting for rollout to complete..."
    success, _ = run_command(
      ["kubectl", "rollout", "status", "deployment/#{@deployment}", "-n", @namespace],
      ""
    )
    
    print_success "Rollout completed" if success
    
    success
  end

  def deploy
    puts "\n" + "="*60
    puts "#{Colors.BOLD}#{Colors.BLUE}Unit Converter EKS Deployment#{Colors.ENDC}"
    puts "="*60 + "\n"
    
    return false unless check_prerequisites
    return false unless verify_cluster_connection
    return false unless create_namespace
    return false unless deploy_manifests
    
    unless @no_wait
      wait_for_deployment
      get_service_endpoint
    end
    
    show_deployment_info
    
    update_deployment_image if @image_uri
    
    puts "\n" + "="*60
    puts "#{Colors.GREEN}#{Colors.BOLD}✓ Deployment completed successfully!#{Colors.ENDC}"
    puts "="*60 + "\n"
    
    true
  end
end

# Parse command line options
options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: deploy.rb [options]"
  
  opts.on("--image-uri URI", "Container image URI") { |v| options[:image_uri] = v }
  opts.on("--namespace NS", "Kubernetes namespace") { |v| options[:namespace] = v }
  opts.on("--deployment DEPLOY", "Deployment name") { |v| options[:deployment] = v }
  opts.on("--service SERVICE", "Service name") { |v| options[:service] = v }
  opts.on("--manifest-dir DIR", "Manifest directory") { |v| options[:manifest_dir] = v }
  opts.on("--wait-time TIME", Integer, "Wait time in seconds") { |v| options[:wait_time] = v }
  opts.on("--no-wait", "Don't wait for deployment") { options[:no_wait] = true }
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Run deployment
deployer = UnitConverterDeployer.new(options)
exit 1 unless deployer.deploy
