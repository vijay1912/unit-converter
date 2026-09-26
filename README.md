# Unit Converter

A simple Spring Boot application for converting between different units of measurement including temperature, length, and weight.

---

## **Table of Contents**
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation and Running](#installation-and-running)
- [API Usage](#api-usage)
  - [REST Endpoints](#rest-endpoints)
    - [Temperature Conversion](#temperature-conversion)
    - [Length Conversion](#length-conversion)
    - [Weight Conversion](#weight-conversion)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Contribution](#contribution)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Contact](#contact)

---

## **Features**

- Temperature conversion (Celsius, Fahrenheit, Kelvin)
- Length conversion (Meter, Kilometer, Mile, Foot, Inch)
- Weight conversion (Kilogram, Gram, Pound, Ounce)
- User-friendly web interface
- RESTful API endpoints for programmatic access

---

## **Technologies Used**

- Java 17
- Spring Boot 3.2.2
- Thymeleaf for server-side templating
- Bootstrap for responsive design
- JUnit 5 for testing

---

## **Getting Started**

### **Prerequisites**

- JDK 17 or later
- Maven 3.6 or later

### **Installation and Running**

1. Clone the repository
```bash
git clone https://github.com/bdkamaci/unit-converter.git
cd unit-converter
```

2. Build the application
```bash
mvn clean install
```

3. Run the application
```bash
mvn spring-boot:run
```

4. Access the application
   Open your browser and navigate to `http://localhost:8080`

---

## **API Usage**

### **REST Endpoints**

#### **Temperature Conversion**
```
POST /api/convert/temperature
Content-Type: application/json

{
  "value": 100,
  "fromUnit": "CELSIUS",
  "toUnit": "FAHRENHEIT"
}
```

#### **Length Conversion**
```
POST /api/convert/length
Content-Type: application/json

{
  "value": 10,
  "fromUnit": "METER",
  "toUnit": "FOOT"
}
```

#### **Weight Conversion**
```
POST /api/convert/weight
Content-Type: application/json

{
  "value": 5,
  "fromUnit": "KILOGRAM",
  "toUnit": "POUND"
}
```

---

## **Running Tests**

```bash
mvn test
```

---

## **Docker and AWS EKS Deployment**

The Dockerfile builds and tests the application in a Maven/Java 17 build stage, then runs the Spring Boot JAR as a non-root user in a Java 17 runtime image. The Helm chart in `deploy/helm/unit-converter` configures the image, namespace, replica count, and Service type. It defaults to two replicas and a private `ClusterIP` Service; set `SERVICE_TYPE=LoadBalancer` when the application should be reachable through an AWS load balancer. An EKS cluster with the appropriate load-balancer controller/configuration may be required.

### Prerequisites

- Docker, AWS CLI, `kubectl`, Helm 3, and permission to push to the existing ECR repository and deploy to the existing EKS cluster.
- An ECR repository already created in the target AWS account and region. EKS worker nodes/Fargate execution role must be allowed to pull from it.

### Build, test, push, and deploy

Set these inputs for the target account and cluster (the account ID is read from the active AWS CLI identity):

```bash
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export EKS_CLUSTER_NAME=my-existing-cluster
export ECR_REPOSITORY=unit-converter
export K8S_NAMESPACE=unit-converter
export REPLICAS=2
export SERVICE_TYPE=ClusterIP
export IMAGE_TAG="$(git rev-parse --short HEAD)"
export IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"
```

Run the application tests, verify AWS identity/cluster and ECR repository access, then build and smoke-test the image locally:

```bash
./mvnw test
aws sts get-caller-identity
aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.status' --output text
aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --region "$AWS_REGION"

docker build --tag "$IMAGE_URI:$IMAGE_TAG" .
docker run --detach --rm --name unit-converter-smoke --publish 8080:8080 "$IMAGE_URI:$IMAGE_TAG"
curl --fail http://localhost:8080/length
docker stop unit-converter-smoke
```

Authenticate Docker to ECR, push the image, configure `kubectl` for the existing cluster, and install or update the Helm release:

```bash
aws ecr get-login-password --region "$AWS_REGION" |
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
docker push "$IMAGE_URI:$IMAGE_TAG"

aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"
helm upgrade --install unit-converter ./deploy/helm/unit-converter \
  --namespace "$K8S_NAMESPACE" --create-namespace \
  --set-string image.repository="$IMAGE_URI" \
  --set-string image.tag="$IMAGE_TAG" \
  --set replicaCount="$REPLICAS" \
  --set service.type="$SERVICE_TYPE" \
  --wait --atomic
kubectl --namespace "$K8S_NAMESPACE" get deployments,services
```

Use a new `IMAGE_TAG` and rerun the build, push, and `helm upgrade --install` commands to update the deployment. For external exposure, set `SERVICE_TYPE=LoadBalancer`; inspect the Service's `EXTERNAL-IP`/hostname with `kubectl` after deployment. To customize the Service port or annotations, replicas, image pull secrets, or resource requests/limits, override the corresponding fields in `values.yaml` with Helm `--set` options or a values file. ECR's standard node/execution-role permissions are preferred over static registry credentials.

---

## **Project Structure**

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── bdkamaci/
│   │           └── unitconverter/
│   │               ├── controller/
│   │               │   └── ConverterController.java
│   │               ├── enums/
│   │               │   ├── LengthUnit.java
│   │               │   ├── TemperatureUnit.java
│   │               │   └── WeightUnit.java
│   │               ├── model/
│   │               │   └── Conversion.java
│   │               ├── service/
│   │               │   ├── ConverterService.java
│   │               │   └── impl/
│   │               │       └── ConverterServiceImpl.java
│   │               └── UnitConverterApplication.java
│   └── resources/
│       ├── static/
│       │   ├── css/
│       │   │   └── style.css
│       │   └── js/
│       │       └── script.js
│       ├── templates/
│       │   ├── index.html
│       │   ├── length.html
│       │   ├── temperature.html
│       │   └── weight.html
│       └── application.properties
└── test/
    └── java/
        └── com/
            └── bdkamaci/
                └── unitconverter/
                    ├── controller/
                    │   └── ConverterControllerTest.java
                    └── service/
                        └── impl/
                            └── ConverterServiceImplTest.java
```

---

## **Contribution**

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---

## **Acknowledgments**

- Spring Boot Documentation
- https://roadmap.sh/projects/unit-converter

---

## **Contact**

Created by Burcu Doga KAMACI - feel free to contact me!

---