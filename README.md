# Register App — DevOps CI/CD Project

A Java-based application deployed through an automated **CI/CD and GitOps pipeline** using Jenkins, Maven, SonarQube, Docker, Trivy, GitHub, Argo CD, Kubernetes, and AWS EKS.

The project demonstrates an end-to-end DevOps workflow from source code commit to a running application on Kubernetes.

## Architecture

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/e1109195-5ca5-4142-a501-457662c6ce3b" />

## Technologies

* **Java / Maven** — Application development and build
* **GitHub** — Source code management
* **Jenkins** — CI/CD automation
* **SonarQube** — Code quality analysis
* **Docker** — Containerization
* **Docker Hub** — Container image registry
* **Trivy** — Container vulnerability scanning
* **Kubernetes** — Container orchestration
* **Amazon EKS** — Managed Kubernetes cluster
* **Argo CD** — GitOps continuous delivery
* **AWS Load Balancer** — External application access

## CI Pipeline

The Jenkins CI pipeline performs the following:

```text
GitHub
  ↓
Checkout
  ↓
Maven Build
  ↓
Unit Tests
  ↓
SonarQube Analysis
  ↓
Quality Gate
  ↓
Docker Build
  ↓
Docker Hub
  ↓
Trivy Scan
```

The Jenkins job uses **Poll SCM** to periodically check the GitHub repository for changes. When a new commit is detected, the CI pipeline starts automatically.

Example image tag:

```text
saikiranreddy5604/register-app-pipeline:1.0.0-37
```

The Jenkins build number is used as part of the image tag so that each build produces a traceable version.

## Code Quality

SonarQube is integrated into the Jenkins pipeline.

```text
Maven
  ↓
SonarQube Analysis
  ↓
Quality Gate
  ├── PASS → Continue
  └── FAIL → Stop Pipeline
```

This ensures that code quality is checked before the application proceeds further in the delivery process.

## Container Security

Docker images are scanned using Trivy before deployment.

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  <image>
```

## GitOps CD

After the CI pipeline creates the Docker image, Jenkins triggers the CD pipeline with the generated `IMAGE_TAG`.

The CD pipeline updates the Kubernetes deployment manifest in the separate GitOps repository:

```text
register-app
     │
     │ IMAGE_TAG
     ▼
Jenkins CD
     │
     ▼
gitops-register-app
     │
     ▼
deployment.yaml
     │
     ▼
Argo CD
     │
     ▼
AWS EKS
```

The GitOps repository acts as the desired state for the Kubernetes deployment.

## Kubernetes Deployment

The application runs as multiple Kubernetes pods inside Amazon EKS.

```text
             AWS EKS
                │
        ┌───────┴───────┐
        ▼               ▼
   Application Pod  Application Pod
        │               │
        └───────┬───────┘
                ▼
       register-app-service
                │
                ▼
        AWS Load Balancer
                │
                ▼
          Application
```

Useful commands:

```bash
kubectl get nodes
kubectl get pods
kubectl get pods -o wide
kubectl get deployments
kubectl get svc
kubectl get endpoints register-app-service
```

## End-to-End Workflow

```text
Code
 ↓
Build
 ↓
Test
 ↓
SonarQube
 ↓
Quality Gate
 ↓
Docker Image
 ↓
Trivy
 ↓
GitOps Update
 ↓
Argo CD Sync
 ↓
AWS EKS
 ↓
Register App
```

## Repository

This repository contains the **application source code and CI implementation**.

The Kubernetes deployment configuration and GitOps implementation are maintained separately in:

**gitops-register-app**

This separation keeps application code and deployment configuration independently version-controlled.

## Learning Reference

This project was built by following and adapting concepts from the **Real Time DevOps Project — Deploy to Kubernetes Using Jenkins** tutorial by **Ashfaque-9x / VirtualTechBox**.

[YouTube Tutorial](https://www.youtube.com/watch?v=e42hIYkvxoQ&utm_source=chatgpt.com)

The implementation was adapted to the project's own application, Jenkins pipelines, Docker images, GitOps workflow, and AWS EKS environment.
