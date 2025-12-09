# GitOps with Kind and ArgoCD

This repository contains the configuration for a GitOps workflow using Kind clusters and ArgoCD.

## Structure:
- `kind-config-gitops.yaml`: Kind cluster configuration.
- `environments/`: Contains application configurations separated by environment.
  - `base/`: Common application manifests.
  - `test/`: Kustomize overlays or Helm values specific to the `test` environment.
  - `prod/`: Kustomize overlays or Helm values specific to the `prod` environment.
- `applications/`: Stores ArgoCD `Application` resources.

## Setup:
1.  **Kind Cluster**: A Kind cluster named `gitops-cluster` is created using `kind-config-gitops.yaml`.
2.  **Namespaces**: `test` and `prod` namespaces are created within the cluster.
3.  **ArgoCD**: ArgoCD is deployed in the `argocd` namespace.
4.  **Git Repository**: This repository is initialized and will be used as the source for ArgoCD.

## Accessing ArgoCD:
To access the ArgoCD UI:
1.  Port-forward the ArgoCD server: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
2.  Open your browser to: `https://localhost:8080`
3.  Login with username `admin` and the initial password (retrieved from `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`).
