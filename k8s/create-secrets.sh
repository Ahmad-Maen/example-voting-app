#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="voting-app"
DOCKER_USERNAME="ahmadmaen"
DOCKER_SERVER="https://index.docker.io/v1/"

cleanup() {
    unset POSTGRES_PASSWORD
    unset POSTGRES_PASSWORD_CONFIRM
    unset DOCKER_HUB_TOKEN
}

trap cleanup EXIT INT TERM

kubectl get namespace "$NAMESPACE" >/dev/null

read -r -s -p "Enter PostgreSQL password: " POSTGRES_PASSWORD
printf '\n'

read -r -s -p "Confirm PostgreSQL password: " POSTGRES_PASSWORD_CONFIRM
printf '\n'

if [[ -z "$POSTGRES_PASSWORD" ]]; then
    printf 'PostgreSQL password cannot be empty.\n' >&2
    exit 1
fi

if [[ "$POSTGRES_PASSWORD" != "$POSTGRES_PASSWORD_CONFIRM" ]]; then
    printf 'PostgreSQL passwords do not match.\n' >&2
    exit 1
fi

kubectl create secret generic postgres-credentials \
    --namespace="$NAMESPACE" \
    --from-literal=POSTGRES_USER=postgres \
    --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    --dry-run=client \
    -o yaml | kubectl apply -f -

kubectl label secret postgres-credentials \
    --namespace="$NAMESPACE" \
    app.kubernetes.io/name=postgres \
    app.kubernetes.io/component=database \
    app.kubernetes.io/part-of=example-voting-app \
    --overwrite

unset POSTGRES_PASSWORD POSTGRES_PASSWORD_CONFIRM

read -r -s -p "Paste Docker Hub read-only token: " DOCKER_HUB_TOKEN
printf '\n'

if [[ -z "$DOCKER_HUB_TOKEN" ]]; then
    printf 'Docker Hub token cannot be empty.\n' >&2
    exit 1
fi

kubectl create secret docker-registry registry-credentials \
    --namespace="$NAMESPACE" \
    --docker-server="$DOCKER_SERVER" \
    --docker-username="$DOCKER_USERNAME" \
    --docker-password="$DOCKER_HUB_TOKEN" \
    --dry-run=client \
    -o yaml | kubectl apply -f -

kubectl label secret registry-credentials \
    --namespace="$NAMESPACE" \
    app.kubernetes.io/name=docker-hub-credentials \
    app.kubernetes.io/part-of=example-voting-app \
    --overwrite

unset DOCKER_HUB_TOKEN

kubectl get secret \
    postgres-credentials \
    registry-credentials \
    --namespace="$NAMESPACE" \
    -o custom-columns='NAME:.metadata.name,TYPE:.type'
