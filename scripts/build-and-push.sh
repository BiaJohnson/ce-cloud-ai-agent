#!/usr/bin/env bash
# Build the ops-agent image with Cloud Build and push to Artifact Registry.
# No local Docker required (AWS analogy: CodeBuild → ECR).

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
REPO="${REPO:-ai-agent}"
TAG="${TAG:-v1}"
IMAGE_NAME="${IMAGE_NAME:-ops-agent}"

REGISTRY="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}"
IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Project: ${PROJECT_ID}"
echo "==> Image:   ${IMAGE}"

gcloud config set project "${PROJECT_ID}" >/dev/null

echo "==> Enabling Cloud Build + Artifact Registry APIs"
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com \
  --project="${PROJECT_ID}"

echo "==> Ensuring Artifact Registry repo '${REPO}' exists"
if ! gcloud artifacts repositories describe "${REPO}" \
  --location="${REGION}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${REPO}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Cloud AI agent PoC images" \
    --project="${PROJECT_ID}"
fi

# Cloud Build's default SA needs permission to push to Artifact Registry
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
echo "==> Granting Artifact Registry Writer to ${CB_SA}"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/artifactregistry.writer" \
  --condition=None \
  >/dev/null

echo "==> Building and pushing ${IMAGE}"
gcloud builds submit "${ROOT}" \
  --tag "${IMAGE}" \
  --project="${PROJECT_ID}"

echo ""
echo "Done. Image:"
echo "  ${IMAGE}"
echo ""
echo "List with:"
echo "  gcloud artifacts docker images list ${REGISTRY}"
