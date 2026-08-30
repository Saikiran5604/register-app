# Register App — CI/CD with Jenkins, Maven, SonarQube, Docker & AWS EKS

A production-style DevOps implementation of a Java/Maven application with an automated CI/CD workflow using **Jenkins, Maven, SonarQube, Docker, Docker Hub, GitHub, GitOps, Argo CD, Kubernetes, and Amazon EKS**.

The project demonstrates how application source code can move from a developer commit through automated build, testing, code-quality analysis, containerization, security scanning, GitOps deployment, and finally run on a Kubernetes cluster.

---

## Architecture

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/2226c137-629b-4492-9645-0deddb6f4b19" />


### End-to-End Flow

```text
Developer
    │
    ▼
GitHub — register-app
    │
    │ Poll SCM
    ▼
Jenkins CI
    │
    ├── Checkout
    ├── Maven Build
    ├── Unit Tests
    ├── SonarQube Analysis
    ├── Quality Gate
    ├── Docker Build
    ├── Docker Hub Push
    └── Trivy Security Scan
            │
            ▼
      Trigger CD Pipeline
            │
            ▼
     GitOps Repository
    gitops-register-app
            │
            ▼
     Argo CD detects change
            │
            ▼
        AWS EKS
            │
      ┌─────┴─────┐
      ▼           ▼
 Application    Service
    Pods       LoadBalancer
      │           │
      └─────┬─────┘
            ▼
       Register App
```

### Core DevOps Flow

```text
Code
  ↓
Build
  ↓
Test
  ↓
Code Quality
  ↓
Quality Gate
  ↓
Docker Image
  ↓
Security Scan
  ↓
GitOps Update
  ↓
Argo CD Sync
  ↓
AWS EKS
  ↓
Application
```

---

## Project Overview

The application is a Java-based registration service packaged using Maven and deployed as a Docker container.

Instead of manually building and deploying the application, the project automates the complete delivery process.

Whenever a change is pushed to the application repository, Jenkins can detect the change through **Poll SCM** and start the CI pipeline.

The CI pipeline:

1. Checks out the latest application source code.
2. Builds the application using Maven.
3. Runs automated tests.
4. Performs SonarQube static code analysis.
5. Validates the SonarQube Quality Gate.
6. Builds a Docker image.
7. Pushes the image to Docker Hub.
8. Performs a Trivy vulnerability scan.
9. Triggers the CD pipeline with the newly generated image tag.

The CD pipeline updates the Kubernetes deployment manifest in the GitOps repository.

Argo CD then detects the Git change and synchronizes the desired state with the AWS EKS cluster.

---

# Technologies Used

| Technology        | Purpose                          |
| ----------------- | -------------------------------- |
| Java              | Application runtime              |
| Maven             | Build and dependency management  |
| GitHub            | Source code management           |
| Jenkins           | CI/CD automation                 |
| SonarQube         | Static code analysis             |
| Docker            | Application containerization     |
| Docker Hub        | Container image registry         |
| Trivy             | Container vulnerability scanning |
| Kubernetes        | Container orchestration          |
| Amazon EKS        | Managed Kubernetes cluster       |
| Argo CD           | GitOps continuous delivery       |
| AWS Load Balancer | External application access      |
| Linux/Ubuntu      | Infrastructure environment       |

---

# CI Pipeline

The CI pipeline is responsible for validating the application and producing a deployable container image.

## 1. Source Code Checkout

Jenkins checks out the application from the GitHub repository.

The Jenkins job is configured to monitor the repository using **Poll SCM**.

For example:

```text
H * * * *
```

This allows Jenkins to periodically check the repository for changes.

If a new commit is detected, Jenkins starts a new CI build.

> Poll SCM checks whether the source repository changed. It does not execute the pipeline every minute when there is no change.

---

## 2. Maven Build

The application is built using Maven.

```bash
mvn clean package
```

This performs the application build and packages the application into its deployable artifact.

The build stage helps ensure that the source code can be compiled successfully before continuing through the pipeline.

---

## 3. Automated Testing

The application tests are executed using:

```bash
mvn test
```

The pipeline stops if the tests fail.

This provides an automated validation point before creating and publishing a Docker image.

---

# SonarQube Code Quality

SonarQube is integrated into Jenkins to perform static code analysis.

The Maven SonarQube scanner is executed from Jenkins:

```bash
mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922:sonar
```

The analysis helps identify issues such as:

* Bugs
* Code smells
* Security-related issues
* Duplicated code
* Maintainability problems
* Reliability problems

---

## Quality Gate

After SonarQube analysis, Jenkins waits for the Quality Gate result.

Conceptually:

```text
Jenkins
   │
   ▼
SonarQube Analysis
   │
   ▼
Quality Gate
   │
   ├── PASS ──► Continue Pipeline
   │
   └── FAIL ──► Stop Pipeline
```

This prevents the pipeline from continuing when the configured SonarQube quality requirements are not satisfied.

The important DevOps concept here is that **quality is treated as a pipeline gate rather than a manual activity**.

---

# Docker Containerization

Once the application passes the quality checks, Jenkins builds a Docker image.

The image follows a versioning convention similar to:

```text
saikiranreddy5604/register-app-pipeline:1.0.0-<BUILD_NUMBER>
```

For example:

```text
saikiranreddy5604/register-app-pipeline:1.0.0-37
```

The Jenkins build number is used as part of the image tag.

This provides a traceable relationship between:

```text
Git Commit
    ↓
Jenkins Build
    ↓
Docker Image Tag
    ↓
Kubernetes Deployment
```

---

# Docker Hub

The generated Docker image is pushed to Docker Hub.

Example:

```bash
docker push saikiranreddy5604/register-app-pipeline:1.0.0-37
```

The pipeline also maintains a `latest` tag for convenience.

However, the deployment process uses the versioned image tag so that each deployment can reference a specific immutable application version.

---

# Trivy Security Scan

Before the pipeline completes, the Docker image is scanned using Trivy.

Example:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image \
  --no-progress \
  --scanners vuln \
  --exit-code 0 \
  --severity HIGH,CRITICAL \
  --format table \
  saikiranreddy5604/register-app-pipeline:1.0.0-37
```

The scan checks the container image for known vulnerabilities.

The project uses the scan as a security visibility step in the CI pipeline.

The broader security workflow is:

```text
Source Code
     ↓
SonarQube
     ↓
Docker Image
     ↓
Trivy
     ↓
Kubernetes Deployment
```

---

# Image Versioning

The application uses the following version format:

```text
1.0.0-${BUILD_NUMBER}
```

For example:

```text
1.0.0-35
1.0.0-36
1.0.0-37
```

This prevents deployments from relying only on the `latest` image tag.

For example:

```text
Build 37
   ↓
Docker Image
   ↓
1.0.0-37
   ↓
GitOps deployment.yaml
   ↓
Kubernetes
```

This also makes it easier to identify which Jenkins build produced a running application version.

---

# CI to CD Trigger

After the Docker image is successfully built and pushed, Jenkins triggers the CD pipeline.

The image tag is passed as a parameter:

```text
IMAGE_TAG=1.0.0-37
```

The request is sent to the Jenkins CD job:

```text
register-app-ci
       │
       │ IMAGE_TAG
       ▼
gitops-register-app-cd
```

The CD pipeline then uses this tag to update the Kubernetes deployment manifest.

---

# GitOps Deployment

The deployment configuration is maintained separately from the application source code.

The GitOps repository is:

```text
gitops-register-app
```

The CI/CD process updates the deployment manifest with the new image version.

For example:

```yaml
image: saikiranreddy5604/register-app-pipeline:1.0.0-37
```

The CD pipeline commits this change back to GitHub.

Example commit:

```text
Updated Deployment Manifest to tag 1.0.0-37 [skip ci]
```

This provides a clear separation:

```text
Application Repository
        │
        │ Source Code
        ▼
    Jenkins CI
        │
        │ Docker Image
        ▼
    Docker Hub
        │
        │ Image Tag
        ▼
    GitOps Repository
        │
        ▼
      Argo CD
        │
        ▼
      AWS EKS
```

---

# Why GitOps?

The GitOps approach makes Git the source of truth for the desired Kubernetes deployment state.

Instead of Jenkins directly running Kubernetes deployment commands, Jenkins updates the GitOps repository.

Argo CD is responsible for applying that desired state to Kubernetes.

This provides:

* Version-controlled deployment configuration
* Clear deployment history
* Auditable changes
* Separation between CI and CD
* Automated synchronization
* Easier rollback
* Declarative infrastructure and deployment management

---

# AWS EKS Deployment

The application is deployed to an Amazon EKS cluster.

The Kubernetes cluster contains:

* Application Deployment
* Application Pods
* Kubernetes Service
* AWS Load Balancer

The deployment runs multiple application replicas.

Conceptually:

```text
                 AWS EKS
                    │
          ┌─────────┴─────────┐
          │                   │
       Pod 1               Pod 2
          │                   │
          └─────────┬─────────┘
                    │
                    ▼
          register-app-service
                    │
                    ▼
             LoadBalancer
                    │
                    ▼
               Internet
```

---

# Kubernetes Deployment

The Kubernetes Deployment defines the desired number of application replicas and the container image that should run.

When the GitOps repository changes from:

```text
1.0.0-36
```

to:

```text
1.0.0-37
```

Argo CD detects the difference between Git and the Kubernetes cluster.

It then synchronizes the cluster with the new desired state.

---

# Kubernetes Service

The application is exposed through a Kubernetes `LoadBalancer` service.

Example:

```bash
kubectl get svc
```

The service provides an AWS Load Balancer endpoint similar to:

```text
a60939f761c394e61a8fc68ec47bd0b6-392129831.ap-south-1.elb.amazonaws.com
```

The service forwards traffic to the application pods on port `8080`.

Example:

```text
Internet
   │
   ▼
AWS Load Balancer
   │
   ▼
register-app-service
   │
   ├── Pod 1 : 8080
   │
   └── Pod 2 : 8080
```

The application can therefore be accessed externally without exposing individual Kubernetes pods.

---

# Useful Kubernetes Commands

Check the running pods:

```bash
kubectl get pods
```

Show additional pod information:

```bash
kubectl get pods -o wide
```

Check services:

```bash
kubectl get svc
```

Check deployments:

```bash
kubectl get deployments
```

Check the service configuration:

```bash
kubectl describe svc register-app-service
```

Check service endpoints:

```bash
kubectl get endpoints register-app-service
```

Check all resources:

```bash
kubectl get all
```

---

# Verifying the Deployment

After Argo CD synchronizes the GitOps repository, the deployment can be verified using:

```bash
kubectl get pods
```

Expected result:

```text
NAME                                      READY   STATUS
register-app-deployment-xxxxx             1/1     Running
register-app-deployment-yyyyy             1/1     Running
```

The service can be checked with:

```bash
kubectl get svc
```

Expected:

```text
NAME                   TYPE           EXTERNAL-IP
register-app-service   LoadBalancer   <AWS-LOAD-BALANCER>
```

The deployment should ultimately result in:

```text
GitHub
   ↓
Jenkins
   ↓
Docker Hub
   ↓
GitOps Repository
   ↓
Argo CD
   ↓
AWS EKS
   ↓
Kubernetes Pods
   ↓
LoadBalancer
   ↓
Register Application
```

---

# Jenkins Infrastructure

The environment uses separate Jenkins infrastructure concepts:

### Jenkins Master

The Jenkins controller manages:

* Jenkins jobs
* Pipeline execution orchestration
* Credentials
* Build configuration
* Pipeline scheduling

### Jenkins Agent

The Jenkins agent performs the actual build operations such as:

```text
Maven
Docker
Trivy
Git
Shell commands
```

This separation allows the Jenkins controller to manage jobs while the agent performs resource-intensive build tasks.

---

# SonarQube Infrastructure

SonarQube uses PostgreSQL as its database.

The basic architecture is:

```text
Jenkins
   │
   │ Maven Sonar Scanner
   ▼
SonarQube
   │
   ▼
PostgreSQL
```

SonarQube analysis results are then used by Jenkins to determine whether the pipeline can continue through the Quality Gate.

---

# EKS Bootstrap Server

A dedicated EC2 instance is used as the administrative/bootstrap server for the Kubernetes environment.

The server contains tools such as:

```text
AWS CLI
kubectl
eksctl
```

AWS authentication can be verified using:

```bash
aws sts get-caller-identity
```

Kubernetes contexts can be checked with:

```bash
kubectl config get-contexts
```

The EKS cluster can then be managed using:

```bash
kubectl get nodes
```

---

# EKS Cluster Management

The EKS cluster can be created using `eksctl`.

A typical command is:

```bash
eksctl create cluster \
  --name <cluster-name> \
  --region ap-south-1 \
  --node-type <node-type> \
  --nodes 3
```

After the cluster is created:

```bash
kubectl get nodes
```

should display the worker nodes.

---

# Argo CD

Argo CD provides the GitOps continuous delivery layer.

Its responsibility is to continuously compare:

```text
Git Desired State
        │
        ▼
     Argo CD
        │
        ▼
Kubernetes Actual State
```

If a difference exists, Argo CD can synchronize the Kubernetes cluster with the configuration stored in Git.

This means deployment does not depend on manually running:

```bash
kubectl apply
```

for every application release.

---

# Complete CI/CD Lifecycle

A typical application release follows this lifecycle:

### 1. Developer changes application code

```text
Developer → GitHub
```

### 2. Jenkins detects the change

```text
GitHub → Jenkins Poll SCM
```

### 3. Application is built

```text
Jenkins → Maven
```

### 4. Tests are executed

```text
Maven → Unit Tests
```

### 5. Code quality is analyzed

```text
Jenkins → SonarQube
```

### 6. Quality Gate is checked

```text
SonarQube → Jenkins
```

### 7. Docker image is created

```text
Application → Docker Image
```

### 8. Image is pushed

```text
Jenkins → Docker Hub
```

### 9. Container vulnerability scan is performed

```text
Docker Image → Trivy
```

### 10. CD pipeline is triggered

```text
CI → CD
```

### 11. GitOps manifest is updated

```text
CD → GitOps Repository
```

### 12. Argo CD detects the change

```text
GitOps Repository → Argo CD
```

### 13. EKS is synchronized

```text
Argo CD → AWS EKS
```

### 14. Kubernetes rolls out the new image

```text
EKS → New Application Pods
```

### 15. Application becomes available

```text
Pods → Service → AWS Load Balancer → User
```

---

# Key DevOps Concepts Demonstrated

## Continuous Integration

Every source-code change can automatically trigger:

```text
Build → Test → Analyze → Package
```

This provides early feedback about application quality.

## Continuous Delivery

The successful CI pipeline produces a versioned container image and passes the image version into the deployment workflow.

## GitOps

Deployment configuration is stored in Git and acts as the desired state for the Kubernetes environment.

## Infrastructure as Code / Declarative Configuration

Kubernetes resources are described declaratively rather than being manually configured on individual servers.

## Quality Gates

SonarQube is integrated directly into the CI pipeline so that code quality becomes part of the automated delivery process.

## Container Security

Trivy scans the Docker image for known vulnerabilities before deployment.

## Immutable Versioning

Build-specific image tags such as:

```text
1.0.0-37
```

allow deployments to reference an exact application version.

## Kubernetes Orchestration

AWS EKS provides the managed Kubernetes environment responsible for running and scaling the application containers.

## Automated Deployment

Argo CD removes the need for manually applying Kubernetes manifests after every release.

---

# Repository Responsibilities

This repository contains the **application and CI-related implementation**.

```text
register-app
     │
     ├── Application Source
     ├── Maven Build
     ├── Tests
     ├── Docker Configuration
     └── Jenkins CI Pipeline
```

The separate GitOps repository contains the deployment configuration:

```text
gitops-register-app
     │
     ├── Kubernetes Deployment
     ├── Kubernetes Service
     └── GitOps Configuration
```

This separation follows the GitOps principle of keeping application source and deployment state independently version-controlled.

---

# What This Project Demonstrates

This project brings together multiple DevOps practices into a single automated workflow:

```text
Source Control
      +
Continuous Integration
      +
Automated Testing
      +
Code Quality
      +
Containerization
      +
Container Security
      +
Container Registry
      +
GitOps
      +
Continuous Delivery
      +
Kubernetes
      +
AWS EKS
```

The final result is an automated delivery pipeline where a code change can progress from GitHub to a running application on AWS EKS with minimal manual intervention.

---

# Learning Reference

This implementation was developed by following and adapting concepts from the **Real Time DevOps Project — Deploy to Kubernetes Using Jenkins / End to End DevOps Project** tutorial by **Ashfaque-9x / VirtualTechBox**.

Tutorial reference: [Real Time DevOps Project — Deploy to Kubernetes Using Jenkins](https://www.youtube.com/watch?v=e42hIYkvxoQ&utm_source=chatgpt.com)

The implementation was adapted to use the project's own repositories, application configuration, Jenkins pipelines, GitOps workflow, Docker images, and AWS EKS environment.

---

# Cleanup

When the environment is no longer required, Kubernetes resources and the EKS cluster can be removed.

Check the resources first:

```bash
kubectl get all
```

Delete the application deployment if required:

```bash
kubectl delete deployment <deployment-name>
```

Delete the service:

```bash
kubectl delete service <service-name>
```

Delete the EKS cluster:

```bash
eksctl delete cluster \
  --region ap-south-1 \
  --name <cluster-name>
```

---
### Result

**Code → Build → Test → Quality → Security → Image → GitOps → Argo CD → EKS → Application**
