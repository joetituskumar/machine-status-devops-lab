# Machine Status DevOps Lab

[![Build and Test Machine API](https://github.com/joetituskumar/machine-status-devops-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/joetituskumar/machine-status-devops-lab/actions/workflows/ci.yml)

A manufacturing-themed DevOps home lab that demonstrates how to build, containerize, publish, and deploy a small **FastAPI** service using **Docker**, **GitHub Actions**, **GitHub Container Registry**, **Kubernetes**, **Helm**, **Argo CD**, and **Terraform**.

The application simulates a simple machine-status service for a factory/manufacturing environment. The API exposes machine health, version information, and sample machine status data such as CNC, press, and robot machines.

> This project is a learning/home-lab project. The focus is not a complex backend application, but the complete DevOps workflow around a small service.

---

## 📌 Project Goal

The goal of this project is to practice an end-to-end DevOps workflow:

1. Build a small FastAPI application.
2. Containerize the application with Docker.
3. Build and push the image using GitHub Actions.
4. Store the container image in GitHub Container Registry.
5. Deploy the application to Kubernetes with Helm.
6. Use Argo CD for GitOps-style deployment.
7. Use Terraform for basic Kubernetes infrastructure setup.

---

## 🏭 Manufacturing Use Case

In a manufacturing environment, services often expose machine health, version, status, sensor, or production data. This project uses a small API to simulate that idea.

Example machine data:

- `CNC-01` - running
- `PRESS-02` - maintenance
- `ROBOT-03` - idle

This makes the project useful for explaining how DevOps can support manufacturing systems through automation, repeatable deployment, health checks, and GitOps.

---

## 📂 Directory Structure

```text
.
├── .github
│   └── workflows
│       └── ci.yml                  # GitHub Actions CI pipeline
├── argocd-app.yaml                 # Argo CD Application manifest
├── machine-status-api
│   ├── app.py                      # FastAPI application
│   ├── Dockerfile                  # Container image definition
│   └── requirements.txt            # Python dependencies
├── machine-status-chart
│   ├── Chart.yaml                  # Helm chart metadata
│   ├── values.yaml                 # Helm configuration values
│   └── templates
│       ├── _helpers.tpl
│       ├── deployment.yaml         # Kubernetes Deployment
│       ├── service.yaml            # Kubernetes Service
│       ├── hpa.yaml                # Optional Horizontal Pod Autoscaler
│       ├── ingress.yaml            # Optional Ingress
│       ├── httproute.yaml          # Optional Gateway API HTTPRoute
│       ├── serviceaccount.yaml
│       └── tests
│           └── test-connection.yaml
├── terraform
│   ├── main.tf                     # Kubernetes namespace and ConfigMap
│   └── terraform.tfstate           # Local Terraform state for home lab
└── README.md
```

---

## 🧰 Prerequisites

For local development:

- Git
- Python 3.12+
- Docker
- GitHub account
- GitHub Container Registry access

For Kubernetes deployment:

- Kubernetes cluster, for example K3s, Minikube, kind, or any local cluster
- kubectl
- Helm
- Terraform
- Argo CD

This project was designed as a home-lab style setup and can be adapted to K3s or Minikube.

---

## ⚙️ 1. Run the FastAPI App Locally

Go to the API folder:

```bash
cd machine-status-api
```

Create and activate a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Start the API:

```bash
uvicorn app:app --host 0.0.0.0 --port 8000
```

Test the endpoints:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/version
curl http://localhost:8000/machines
```

Open the FastAPI documentation:

```text
http://localhost:8000/docs
```

---

## 🐳 2. Build and Run with Docker

Build the Docker image:

```bash
cd machine-status-api
docker build -t machine-status-api:local .
```

Run the container:

```bash
docker run --rm -p 8000:8000 machine-status-api:local
```

Test it:

```bash
curl http://localhost:8000/health
```

The application listens on port `8000` inside the container.

---

## 🔁 3. GitHub Actions CI Pipeline

The CI workflow is located at:

```text
.github/workflows/ci.yml
```

The pipeline runs when files inside `machine-status-api/**` change. It performs these steps:

1. Checks out the source code.
2. Sets up Python 3.12.
3. Installs dependencies.
4. Runs a basic Python syntax check.
5. Logs in to GitHub Container Registry.
6. Builds a Docker image.
7. Pushes the image to GHCR using the Git commit SHA as the image tag.

Image format:

```text
ghcr.io/joetituskumar/machine-status-api:<git-commit-sha>
```

Using the commit SHA as the image tag makes the deployment traceable because every running image can be connected back to the exact Git commit that created it.

---

## 🔐 4. GitHub Container Registry

The workflow uses the built-in `GITHUB_TOKEN` to push images to GitHub Container Registry.

Required workflow permissions:

```yaml
permissions:
  contents: read
  packages: write
```

The pipeline already includes these permissions.

After a successful pipeline run, the container image is published to GHCR.

---

## ☸️ 5. Kubernetes and Helm Deployment

The Helm chart is located at:

```text
machine-status-chart/
```

The chart contains Kubernetes manifests for:

- Deployment
- Service
- ServiceAccount
- Readiness probe
- Liveness probe
- Optional HPA
- Optional Ingress
- Optional HTTPRoute

Install the chart manually:

```bash
helm upgrade --install machine-status-api ./machine-status-chart \
  --namespace manufacturing \
  --create-namespace
```

Check the resources:

```bash
kubectl get pods -n manufacturing
kubectl get svc -n manufacturing
kubectl get deployments -n manufacturing
```

Port-forward to test the service:

```bash
kubectl get svc -n manufacturing
kubectl port-forward -n manufacturing svc/<service-name> 8000:8000
```

Then test:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/machines
```

> Note: Depending on the Helm release name, the generated Service name may differ. Use `kubectl get svc -n manufacturing` to confirm the exact service name.

---

## ✅ Important Port Note

The FastAPI container runs on port `8000`.

Before deploying, make sure the Helm service and deployment port are aligned with the application port:

```yaml
service:
  type: ClusterIP
  port: 8000
```

The liveness and readiness probes also check `/health` on port `8000`.

This is a common Kubernetes debugging point: the container port, service target port, and health probe port must match the actual application port.

---

## 🚀 6. Argo CD GitOps Deployment

The Argo CD application file is:

```text
argocd-app.yaml
```

It tells Argo CD to:

- Watch this GitHub repository.
- Use the `main` branch.
- Deploy the Helm chart from `machine-status-chart/`.
- Deploy into the `manufacturing` namespace.
- Automatically sync changes.
- Self-heal if the cluster drifts from the desired Git state.
- Prune removed resources.

Apply the Argo CD application:

```bash
kubectl apply -f argocd-app.yaml
```

Check the Argo CD namespace:

```bash
kubectl get pods -n argocd
```

Port-forward the Argo CD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

After sync, Argo CD deploys the Helm chart into the Kubernetes cluster.

---

## 🏗️ 7. Terraform Setup

Terraform is used for basic Kubernetes infrastructure setup.

Terraform file:

```text
terraform/main.tf
```

It creates:

- `manufacturing` namespace
- `machine-api-config` ConfigMap

Run Terraform:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Check the namespace:

```bash
kubectl get namespace manufacturing
```

Check the ConfigMap:

```bash
kubectl get configmap machine-api-config -n manufacturing -o yaml
```

> Production note: Terraform state should normally be stored in a remote backend and not committed to Git. In this home-lab project, local state is used for learning purposes.

---

## 🌐 API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/health` | GET | Returns service health |
| `/version` | GET | Returns app version and deployment timestamp |
| `/machines` | GET | Returns sample manufacturing machine status data |
| `/docs` | GET | FastAPI Swagger UI |
| `/redoc` | GET | FastAPI ReDoc UI |

Example:

```bash
curl http://localhost:8000/machines
```

Example response:

```json
{
  "machines": [
    {
      "id": "CNC-01",
      "status": "running",
      "temperature": 67
    },
    {
      "id": "PRESS-02",
      "status": "maintenance",
      "temperature": 40
    },
    {
      "id": "ROBOT-03",
      "status": "idle",
      "temperature": 51
    }
  ]
}
```

---

## 🧪 Useful Commands

Check pods:

```bash
kubectl get pods -n manufacturing
```

Check logs:

```bash
kubectl logs -n manufacturing deploy/<deployment-name>
```

Describe a pod:

```bash
kubectl describe pod -n manufacturing <pod-name>
```

Check service:

```bash
kubectl get svc -n manufacturing
```

Render Helm templates locally:

```bash
helm template machine-status-api ./machine-status-chart
```

Run Helm test:

```bash
helm test machine-status-api -n manufacturing
```

---

## 🧭 DevOps Architecture

```text
Developer
   |
   | git push
   v
GitHub Repository
   |
   | GitHub Actions
   v
Build + Syntax Check + Docker Build
   |
   | push image
   v
GitHub Container Registry
   |
   | image referenced in Helm values
   v
Helm Chart in Git
   |
   | watched by Argo CD
   v
Kubernetes Cluster
   |
   | runs
   v
Machine Status API
```
---

## 🛠️ Planned Improvements

Next improvements:

- Add automated API tests with `pytest`
- Add Prometheus metrics endpoint
- Add resource requests and limits
- Add a `.gitignore` for local files and Terraform state
- Move Terraform state to a safer backend
- Add screenshots of Argo CD, Kubernetes pods, and API responses
- Add Argo CD Image Updater or another image promotion mechanism
- Add monitoring dashboard with Grafana
- Improve security context for the container
- Add separate dev/stage/prod Helm values

---

## 📷 Screenshots

Screenshots will be added later for:

- GitHub Actions successful workflow
- GHCR container image package
- Argo CD application synced/healthy state
- Kubernetes pods running
- FastAPI `/docs` page
- `/machines` API response

Suggested folder:

```text
docs/images/
```

Example Markdown format:

```md
![Argo CD Application](docs/images/argocd-application.png)
```

---

## 📌 Current Status

This project currently demonstrates a working DevOps learning flow for a small manufacturing-style API.

It is intentionally simple and will be improved step by step as part of a home-lab DevOps practice project.
