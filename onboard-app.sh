#!/bin/bash

set -euo pipefail

APP_NAME="$1" #"hello-gitops"
ENV="$2"

if [ -z "$APP_NAME" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 <app-name> <environment>"
  echo "Example: $0 my-new-app dev"
  exit 1
fi

GITOPS_REPO_PATH="."
ARGO_APP_OVERLAY_PATH="$GITOPS_REPO_PATH/applications/overlays/$APP_NAME-$ENV"
ARGO_APP_TEMPLATE="$GITOPS_REPO_PATH/applications/overlays/template-app/kustomization-template.yaml"
APP_TEMPLATES_SOURCE_PATH="$GITOPS_REPO_PATH/apps/template-app"
APP_TARGET_PATH="$GITOPS_REPO_PATH/apps/$APP_NAME"

echo "Onboarding application '$APP_NAME' for environment '$ENV'..."

# --- Create directory structure for ArgoCD Application Overlay ---
mkdir -p "$ARGO_APP_OVERLAY_PATH"
echo "Created directory: $ARGO_APP_OVERLAY_PATH"

# --- Copy and customize ArgoCD Application Overlay ---
# Generate and write the customized ArgoCD Application overlay directly
cat <<EOF > "$ARGO_APP_OVERLAY_PATH/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base

patches:
  - target:
      group: argoproj.io
      version: v1alpha1
      kind: Application
      name: REPLACE_APP_NAME-REPLACE_ENV # This must match the base argocd-app.yaml placeholder
    patch: |-
      - op: replace
        path: /metadata/name
        value: $APP_NAME-$ENV
      - op: replace
        path: /spec/destination/namespace
        value: $ENV
      - op: replace
        path: /spec/source/path
        value: apps/$APP_NAME
EOF
echo "Customized ArgoCD Application overlay for $APP_NAME in $ENV."

# --- Create directory and copy template for application Deployment and Service ---
mkdir -p "$APP_TARGET_PATH"
echo "Created directory: $APP_TARGET_PATH"

if [ -d "$APP_TEMPLATES_SOURCE_PATH" ]; then
  cp -R "$APP_TEMPLATES_SOURCE_PATH"/* "$APP_TARGET_PATH/"
  echo "Copied all templates from $APP_TEMPLATES_SOURCE_PATH to: $APP_TARGET_PATH"
  # Customize generic deployment/service files
  for file in "$APP_TARGET_PATH"/*.yaml; do
    sed -i '' "s|ai-ui-backend|$APP_NAME|g" "$file"
    sed -i '' "s|ai-ui-backend-service|$APP_NAME-service|g" "$file"
    # Placeholder for image customization if needed, e.g.:
    # sed -i '' "s|ghcr.io/umeshpoojariaws/ai-ui-backend:.*|ghcr.io/umeshpoojariaws/$APP_NAME:$IMAGE_TAG|g" "$file"
  done
else
  echo "Error: Application templates source directory not found at $APP_TEMPLATES_SOURCE_PATH."
  exit 1
fi

# --- Apply the new ArgoCD Application to the cluster ---
echo "Applying ArgoCD Application for $APP_NAME in $ENV..."
kubectl apply -k "$ARGO_APP_OVERLAY_PATH" -n argocd
echo "ArgoCD Application for $APP_NAME in $ENV applied successfully."

echo "Application '$APP_NAME' onboarded to ArgoCD for environment '$ENV'."
