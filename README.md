# Secure EKS Pipeline for FastAPI

**[Read the full blog post here](https://dev.to/dhayv/build-a-secure-cicd-pipeline-for-amazon-eks-using-github-actions-and-aws-oidc-3b0m/edit)

## Overview
This repository demonstrates how to build a **secure AWS EKS (Kubernetes) CI/CD pipeline** for a **FastAPI** application using **GitHub Actions**, **Docker**, and **OpenID Connect (OIDC)**. It follows **AWS security best practices** such as least-privilege IAM policies, private cluster endpoints, and automatic deployments—**all without storing static AWS credentials** in your repository.

## Prerequisites
- **AWS Account** with permissions to create EKS clusters, ECR repositories, and IAM roles  
- **AWS CLI** installed and configured  
- **eksctl** installed ([Installation Guide](https://eksctl.io/installation/))  
- **Docker** installed ([Get Started with Docker](https://www.docker.com/get-started/))  
- **kubectl** installed  
- Familiarity with basic Kubernetes concepts (Deployments, Services, etc.)

### OIDC + GitHub Actions
- OpenID Connect eliminates the need for long-lived AWS credentials in GitHub
- Configure a GitHub OIDC Identity Provider in AWS IAM, create a role with least-privilege permissions for ECR/EKS, and reference that role in the GitHub Actions workflow

### Docker & Amazon ECR
- A Dockerfile is provided for building a container image of your FastAPI app
- Amazon ECR stores the Docker images. The GitHub Actions workflow will log in to ECR, build, tag, and push images based on commit SHAs

### Kubernetes Manifests
- `fastapi-deploy.yaml`: Defines the Deployment for your FastAPI containers
- `fastapi-service.yaml`: Defines a Service (LoadBalancer or ClusterIP) that exposes the application within or outside the cluster

## Important Notes
- **Security:** By using OIDC, no long-term AWS credentials are committed to the repository
- **Least Privilege:** Restrict roles to ECR and EKS cluster admin actions only, avoiding overly broad permissions
- **Scalability:** EKS automatically handles scaling your pods as needed (or use the Kubernetes Horizontal Pod Autoscaler)

## Repository Structure
```bash
├── main.py                # FastAPI application
├── Dockerfile             # Docker configuration
├── fastapi-deploy.yaml    # Kubernetes Deployment manifest
├── fastapi-service.yaml   # Kubernetes Service manifest
└── requirements.txt       # Python dependencies

```
## Clone the Repository

```bash
git clone https://github.com/dhayv/kubectl-blog.git
cd kubectl-blog
```

## Configure AWS Credentials

Make sure your AWS CLI is set up with the correct profile and region:

```bash
aws configure
aws sts get-caller-identity
```

### GitHub Actions Workflow (sample)

```yaml
name: Deploy to AWS
on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to ECR
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build & Push Image
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          REPOSITORY: fastapi-app
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $REGISTRY/$REPOSITORY:$IMAGE_TAG .
          docker push $REGISTRY/$REPOSITORY:$IMAGE_TAG

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name ${{ secrets.EKS_CLUSTER_NAME }} --region ${{ secrets.AWS_REGION }}

      - name: Deploy to EKS
        env:
          REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          REPOSITORY: fastapi-app
          IMAGE_TAG: ${{ github.sha }}
        run: |
          sed -i.bak "s|DOCKER_IMAGE|$REGISTRY/$REPOSITORY:$IMAGE_TAG|g" fastapi-deploy.yaml
          kubectl apply -f fastapi-deploy.yaml
          kubectl apply -f fastapi-service.yaml
```

**Tip:** Store variables like `AWS_ROLE_ARN`, `AWS_REGION`, and `EKS_CLUSTER_NAME` as GitHub Secrets to avoid exposing sensitive data.

## Resource Cleanup

When you're done, it's best to delete unneeded resources to avoid costs:

```bash
# If using Terraform
terraform destroy -auto-approve

# If using eksctl
eksctl delete cluster --name fastapi-demo
```

Also, remove the ECR repository if you no longer need it:

```bash
aws ecr delete-repository --repository-name fastapi-app --force
```

## Further Reading
- Full CI/CD Deployment Guide
- AWS EKS Documentation
- GitHub Actions with OIDC
- FastAPI Official Docs

Happy Deploying! 🚀
