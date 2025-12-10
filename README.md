# GitOps with Kind and ArgoCD

This repository contains the configuration for a GitOps workflow using Kind clusters and ArgoCD.

## Structure:
- `kind-config-gitops.yaml`: Configuration for the Kind Kubernetes cluster.
- `ci-cd-script.sh`: Script for CI/CD pipeline automation.
- `install-argocd.sh`: Script to install ArgoCD on the Kind cluster.
- `onboard-app.sh`: Script to onboard new applications into the GitOps setup.
- `namespaces/`: Kubernetes namespace definitions.
  - `dev-namespace.yaml`: Development namespace definition.
  - `prod-namespace.yaml`: Production namespace definition.
  - `test-namespace.yaml`: Test namespace definition.
- `apps/`: Core Kubernetes manifests for applications.
  - `backend/`: Kubernetes deployments, services, and environment-specific values for the backend application.
  - `frontend/`: Kubernetes deployments, services, and environment-specific values for the frontend application.
  <!-- - `template-app/`: Template for new application manifests. -->
- `applications/`: GitOps configurations, including ArgoCD Application definitions and Kustomize overlays.
  <!-- - `argocd-apps/`: ArgoCD `Application` resources defining the synchronization of applications.
    - `nginx-dev-app.yaml`: ArgoCD application definition for Nginx in the development environment.
    - `nginx-prod-app.yaml`: ArgoCD application definition for Nginx in the production environment. -->
  - `base/`: Base Kubernetes manifests and Kustomization files for shared configurations.
  - `overlays/`: Kustomize overlays for environment-specific configurations.
    - `backend-dev/`: Development environment overlay for the backend application.
    - `frontend-dev/`: Development environment overlay for the frontend application.
    - `template-app/`: Template for application overlays.

## Getting Started:

This guide provides step-by-step instructions to set up and interact with this GitOps environment.

### Prerequisites:

Ensure you have the following tools installed on your machine:
-   **Docker**: For running Kind clusters.
-   **kubectl**: Kubernetes command-line tool.
-   **kind**: Kubernetes in Docker.
-   **helm**: Kubernetes package manager (optional, but useful for some applications).
-   **argocd CLI**: ArgoCD command-line interface.

### Steps:

1.  **Create the Kind Cluster**:
    ```bash
    kind create cluster --config kind-config-gitops.yaml --name gitops-cluster
    ```

2.  **Install ArgoCD**:
    ```bash
    ./install-argocd.sh
    ```
    This script will deploy ArgoCD into the `argocd` namespace.

3.  **Onboard an Example Application (e.g., Backend)**:
    To deploy the backend application to the `dev` namespace:
    ```bash
    ./onboard-app.sh backend dev
    ```
    This command will:
    *   Create the `dev` namespace if it doesn't exist.
    *   Generate the `backend-dev` overlay in `applications/overlays/backend-dev/`.
    *   Create an ArgoCD Application resource in `applications/argocd-apps/backend-dev-app.yaml`.
    *   Synchronize the application with the cluster via ArgoCD.

4.  **Access ArgoCD UI**:
    To access the ArgoCD dashboard:
    1.  Port-forward the ArgoCD server:
        ```bash
        kubectl port-forward svc/argocd-server -n argocd 8080:443 &
        ```
    2.  Open your browser to: `https://localhost:8080`
    3.  Login with username `admin` and retrieve the initial password:
        ```bash
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        ```

5.  **Verify Application Deployment**:
    In the ArgoCD UI, you should see the `backend-dev` application synchronized and healthy. You can also check Kubernetes resources directly:
    ```bash
    kubectl get deployments -n dev
    kubectl get services -n dev
    ```



## GitHub Personal Access Tokens (PATs) Configuration

GitHub Personal Access Tokens (PATs) are essential for authenticating with GitHub services, including pushing and pulling Docker images from GitHub Container Registry (ghcr.io).

1.  **Generate a GitHub Personal Access Token (PAT)**:
    *   Go to your GitHub settings: `Settings` > `Developer settings` > `Personal access tokens` > `Tokens (classic)`.
    *   Click `Generate new token` (classic).
    *   Give it a descriptive name (e.g., `CI/CD-PAT`).
    *   Set an expiration.
    *   Crucially, grant the following scopes:
        *   For **pushing images from GitHub Actions to GHCR**: `write:packages` and `read:packages` (or `repo` for full repository access).
        *   For **pulling images into Kubernetes from GHCR**: `read:packages`.
    *   Generate the token and **copy it immediately** as you won't be able to see it again.

2.  **Configure PAT for GitHub Actions (`GHCR_PAT` Secret)**:
    *   This PAT is used by your CI workflow to push images to `ghcr.io`.
    *   Go to your GitHub repository: `Settings` > `Secrets and variables` > `Actions` > `Repository secrets`.
    *   Click `New repository secret`.
    *   Name it `GHCR_PAT`.
    *   Paste the PAT you generated (with `write:packages` scope) as its value.

3.  **Create Kubernetes `imagePullSecret` (`ghcr-login-secret`)**:
    *   This secret allows your Kind cluster to pull images from `ghcr.io`.
    *   Replace `<YOUR_GITHUB_USERNAME>` with your GitHub username, `<YOUR_PAT_WITH_READ_PACKAGES>` with a PAT (from step 1, with `read:packages` scope), and `<YOUR_GITHUB_EMAIL>` with your GitHub email.
    *   Run this command on your local machine (after your Kind cluster is running):
    ```bash
    kubectl create secret docker-registry ghcr-login-secret \
      --namespace default \
      --docker-server=ghcr.io \
      --docker-username=<YOUR_GITHUB_USERNAME> \
      --docker-password=<YOUR_PAT_WITH_READ_PACKAGES> \
      --docker-email=<YOUR_GITHUB_EMAIL>
    ```
