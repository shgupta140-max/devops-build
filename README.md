# ReactJS Application Deployment Project

## Overview
This repository contains the production-ready deployment setup for a ReactJS frontend application. The project is designed to build a static React app, package it into a lightweight NGINX-based Docker image, and deploy it through a Jenkins CI/CD pipeline to an AWS EC2 instance.

The deployment flow follows a modern DevOps pattern with automated containerization, image tagging, Docker Hub publishing, and secure remote deployment using SSH and AWS Systems Manager Parameter Store.

---

## Project Purpose
The main goal of this repository is to provide a clean and reusable pipeline for:
- building the React application
- containerizing the built static assets with NGINX
- pushing Docker images to Docker Hub
- deploying the application to an EC2 host in AWS
- handling dev and production branch-based deployment workflows

---

## Application Architecture

### Runtime Architecture
- Frontend: ReactJS application
- Web server: NGINX Alpine
- Container orchestration: Docker
- CI/CD orchestration: Jenkins
- Image registry: Docker Hub
- Cloud host: AWS EC2
- Secrets and environment metadata: Jenkins credentials and AWS SSM Parameter Store

### Request Flow
1. Developer pushes code to the repository.
2. Jenkins detects the branch and triggers the relevant pipeline.
3. The React build is packaged into a Docker image.
4. The image is tagged and pushed to Docker Hub.
5. For production deployment, Jenkins pulls the image on the EC2 instance and runs it on port 80.
6. NGINX serves the application and handles SPA routing.

---

## Repository Structure

```text
devops-build/
├── build.sh                 # Builds and pushes Docker image
├── Dockerfile               # NGINX-based container definition
├── Jenkinsfile              # CI/CD pipeline definition
├── nginx.conf               # NGINX reverse proxy and static serving config
├── compose.yaml             # Local Docker Compose configuration
├── deploy.sh                # EC2 bootstrap / deployment helper
├── .dockerignore            # Excludes unnecessary files during Docker build
├── .gitignore               # Git ignore rules
├── build/                   # React production build output
├── README.md                # Project documentation
└── ...
```

---

## Infrastructure Repository
This application is deployed using infrastructure created from the companion repository named `reactjs-infra`.

The `reactjs-infra` repository is responsible for provisioning the underlying deployment environment, including:
- AWS EC2 instance setup
- required networking and security configuration
- IAM and access policies
- Docker runtime setup on the server
- parameter store configuration such as the public IP used by the Jenkins pipeline
- foundational infrastructure needed to host the application securely on AWS

The Jenkins pipeline in this repository reads the EC2 public IP from AWS SSM using the parameter name:

```text
ReactJS_Node_Public_IP
```

This ensures the deployment step is environment-driven and not hardcoded into the Jenkins job.

---

## Build and Deployment Workflow

### 1. Docker Image Build
The Docker image is created using the `Dockerfile` and the application static build output stored in the `build/` directory.

```dockerfile
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm *.html
COPY build/ .
COPY ./nginx.conf /etc/nginx/conf/nginx.conf
```

This image serves the built React app through NGINX while exposing port 80.

### 2. Image Tagging and Publishing
The build script creates a Docker image with a tag in the format:

```bash
<repository>:reactjs-app-<build-number>
```

Example:

```bash
sh ./build.sh shgupta140/dev 42
```

This results in an image named:

```text
shgupta140/dev:reactjs-app-42
```

### 3. Jenkins Pipeline Logic
The pipeline is configured in `Jenkinsfile` and supports branch-specific deployments:

- `origin/dev` -> dev image build and push
- `origin/main` -> production image build and push
- `origin/main` -> EC2 deployment to production instance

The pipeline uses Jenkins credentials for:
- Docker Hub authentication
- EC2 SSH access
- Slack notification integration

---

## Build Script Configuration
The `build.sh` file performs the image build and push process.

```bash
#!/bin/bash
echo "=============== Building the Image ==============="
IMAGE_NAME="reactjs-app"
docker build -t $1:$IMAGE_NAME-$2 . &> /tmp/build.log || { echo "Docker build failed. Check build.log for details."; exit 1; }
echo "=============== Build Complete ==============="
echo "=============== Pushing Image to $1 ============"
docker push $1:$IMAGE_NAME-$2 &>> /tmp/push.log || { echo "Docker push failed, Check push.log for details."; exit 1; }
echo "=============== Image Pushed to repository =========="
```

This script is intentionally simple and focused on build validation plus Docker registry publishing.

---

## Local Docker Compose Setup
The `compose.yaml` file provides a local container startup configuration for the app.

```yaml
services:
  reactjs-app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "80:80"
```

Run locally with:

```bash
docker compose up --build -d
```

Then access the application via:

```text
http://localhost
```

---

## NGINX Configuration
The `nginx.conf` file configures NGINX for serving a React SPA correctly.

Key behaviors:
- listens on port 80
- serves the app from `/usr/share/nginx/html`
- supports client-side routing using `try_files`
- caches static assets such as JS and CSS for performance
- handles common error pages gracefully

This is essential because React applications often use client-side routing, which requires fallback routing to `index.html`.

---

## Deployment to EC2
The production deployment step in the Jenkins pipeline performs the following actions:

1. Reads the EC2 instance IP from AWS SSM Parameter Store.
2. Connects to the EC2 instance securely over SSH.
3. Logs into Docker Hub using Jenkins credentials.
4. Pulls the production Docker image.
5. Removes any previous container instance.
6. Starts a new container named `reactjs-app`.
7. Validates the health of the app by hitting `http://127.0.0.1:80/`.

The container is started with:

```bash
docker run -d --name reactjs-app --restart unless-stopped -p 80:80 "$IMAGE"
```

This ensures the service remains available after reboot and is exposed on the default web port.

---

## Jenkins Pipeline Details
The `Jenkinsfile` includes the following stages:

### Check Docker Version
Verifies Docker is available in the Jenkins environment.

### Docker Login
Authenticates with Docker Hub using Jenkins credentials.

### Dev Flow: Build & Push
Triggered for the `dev` branch and pushes images to the development Docker repository.

### Prod Flow: Build & Push
Triggered for the `main` branch and pushes images to the production Docker repository.

### Deploying Application
Executed only for the `main` branch. It deploys the production image to AWS EC2.

### Post-build actions
- workspace cleanup
- Docker logout
- Slack notification on success or failure

---

## Environment and Credentials
The pipeline expects the following Jenkins-managed credentials and variables:

```text
DockerHubCredentials
EC2_SSH_CREDENTIALS
ReactJS_Node_Public_IP
AWS_REGION = ap-south-1
EC2_SSH_USER = ubuntu
SLACK_CHANNEL = #reactjs-app-pipeline
```

These values are used to securely authenticate and orchestrate deployment across the ecosystem without exposing sensitive values directly in the repository.

---

## Branch Strategy
This project follows a simple but reliable branch-based deployment strategy:

- `dev` branch: used for development image builds and testing
- `main` branch: used for production-ready artifacts and deployment

This separation helps ensure the production environment only receives code that has been merged and approved for release.

---

## Deployment Helper Script
The `deploy.sh` file supports provisioning the EC2 server and installing the necessary Docker dependencies.

It performs the following tasks:
- updates the system packages
- installs Docker and required utilities
- configures Docker package repositories
- adds the current user to the Docker group
- creates application directories
- builds the application image
- deploys it with Docker Compose

This is useful for a fresh EC2 instance setup or environment bootstrapping.

---

## Security Considerations
The deployment setup incorporates several security best practices:
- credentials are handled via Jenkins secret storage
- SSH access is performed using a private key from Jenkins
- Docker Hub credentials are injected at runtime instead of being stored in the repo
- `.dockerignore` prevents unnecessary files from being included in the build context
- the EC2 instance runs the service with a restart policy to improve resilience

---

## Troubleshooting
### Docker build fails
Check the `/tmp/build.log` file generated by the build script.

### Docker push fails
Inspect `/tmp/push.log` for image upload issues.

### Container does not start
Check logs from the running container:

```bash
docker logs reactjs-app
```

### App not reachable on port 80
Verify:
- the container is running
- port 80 is exposed
- the EC2 security group allows inbound HTTP traffic
- the NGINX config is valid

---

## Useful Commands

### Build image manually
```bash
docker build -t reactjs-app:local .
```

### Run locally with Docker Compose
```bash
docker compose up --build -d
```

### Stop local container
```bash
docker compose down
```

### Pull and run production image manually
```bash
docker pull <dockerhub-repo>:reactjs-app-<build-number>
docker run -d --name reactjs-app -p 80:80 <dockerhub-repo>:reactjs-app-<build-number>
```

---

## Summary
This repository provides a complete and reusable deployment pipeline for a ReactJS application using Docker, Jenkins, AWS EC2, Docker Hub, and NGINX. It follows industry-standard CI/CD practices and is designed to support reliable dev and production deployment workflows.

The infrastructure required to host this application is managed through the `reactjs-infra` repository, which provisions the AWS environment for the deployment.

---

## Maintainer
This project is maintained for automated deployment and operational continuity of the ReactJS application environment.

