#!/usr/bin/env bash
set -euo pipefail

K8S_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${K8S_DIR}/all.yaml"

FILES=(
    "common/namespace.yaml"
    "common/configmap.yaml"
    "db/persistent-volume.yaml"
    "db/persistent-volume-claim.yaml"
    "db/services.yaml"
    "db/statefulset.yaml"
    "redis/service.yaml"
    "redis/deployment.yaml"
    "worker/deployment.yaml"
    "vote/service.yaml"
    "vote/deployment.yaml"
    "vote/hpa.yaml"
    "result/service.yaml"
    "result/deployment.yaml"
    "networking/ingress.yaml"
    "networking/network-policies.yaml"
)

TEMP_FILE="$(mktemp "${K8S_DIR}/.all.yaml.XXXXXX")"

cleanup() {
    rm -f "$TEMP_FILE"
}

trap cleanup EXIT

first_file=true

for relative_path in "${FILES[@]}"; do
    source_file="${K8S_DIR}/${relative_path}"

    if [[ ! -f "$source_file" ]]; then
        printf 'Missing manifest: %s\n' "$source_file" >&2
        exit 1
    fi

    if [[ "$first_file" == false ]]; then
        printf '\n---\n' >> "$TEMP_FILE"
    fi

    cat "$source_file" >> "$TEMP_FILE"
    first_file=false
done

mv "$TEMP_FILE" "$OUTPUT"
trap - EXIT

printf 'Generated %s from %d canonical files.\n' \
    "$OUTPUT" "${#FILES[@]}"
